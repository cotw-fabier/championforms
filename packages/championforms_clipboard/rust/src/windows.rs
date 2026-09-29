//! Clipboard backend: Windows (Win32 clipboard API, no OLE).
//!
//! See platform.rs for the contract. Every operation runs on one dedicated
//! clipboard thread, started lazily, that owns a message-only window
//! (`HWND_MESSAGE`). A real owner window is required: after
//! `OpenClipboard(NULL)`, `EmptyClipboard` leaves the clipboard with no
//! owner and `SetClipboardData` fails. The thread pumps messages so that
//! other processes' `SendMessage`s to the clipboard owner (e.g.
//! `WM_DESTROYCLIPBOARD` when they empty the clipboard) never block.
//!
//! Writes are eager: every format's bytes are handed to the system in an
//! `HGLOBAL`, so there is no delayed rendering (`WM_RENDERFORMAT`) to serve.
//!
//! Format mapping (lib/src/ffi/ABI.md):
//! - `text/plain` → `CF_UNICODETEXT` (UTF-16LE, NUL-terminated). Windows
//!   synthesizes `CF_TEXT`/`CF_OEMTEXT` from it for legacy readers.
//! - `text/html`  → registered `HTML Format` (CF_HTML, see cf_html.rs).
//! - `text/rtf`   → registered `Rich Text Format`.
//! - `image/png`  → registered `PNG` (no `CF_DIB` fallback is written).
//! - `image/gif`  → registered `GIF`.
//! - `files`      → `CF_HDROP` (a `DROPFILES` list, see hdrop.rs), which
//!   Explorer pastes as a copy of the files.
//! - `custom:<n>` → registered format `<n>`.
//!
//! Format-name handling mirrors super_native_extensions' win32/common.rs
//! (`format_from_string`/`format_to_string`) and its CF_HTML/UTF-16
//! conversions (Copyright (c) 2022 Superlist, Matej Knopp and the
//! contributors, MIT); its COM IDataObject and lazy providers are dropped.

use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::OnceLock;
use std::sync::mpsc::{Receiver, Sender, channel};
use std::time::Duration;

use windows::Win32::Foundation::{GlobalFree, HANDLE, HGLOBAL, HWND, LPARAM, WPARAM};
use windows::Win32::System::DataExchange::{
    CloseClipboard, EmptyClipboard, EnumClipboardFormats, GetClipboardData,
    GetClipboardFormatNameW, IsClipboardFormatAvailable, OpenClipboard, RegisterClipboardFormatW,
    SetClipboardData,
};
use windows::Win32::System::Memory::{
    GMEM_MOVEABLE, GlobalAlloc, GlobalLock, GlobalSize, GlobalUnlock,
};
use windows::Win32::System::Ole::{CF_HDROP, CF_OEMTEXT, CF_TEXT, CF_UNICODETEXT};
use windows::Win32::UI::WindowsAndMessaging::{
    CreateWindowExW, DispatchMessageW, GetMessageW, HWND_MESSAGE, MSG, PostMessageW,
    WINDOW_EX_STYLE, WINDOW_STYLE, WM_APP,
};
use windows::core::{PCWSTR, w};

use crate::cf_html;
use crate::format::{Format, decode_paths, encode_paths};
use crate::hdrop;
use crate::platform::{ClipError, Done, Entries};

// ---------------------------------------------------------------------------
// Clipboard thread
// ---------------------------------------------------------------------------

/// A unit of work run on the clipboard thread with the owner window, or
/// with `None` when the thread is gone (the job then only reports failure).
type Job = Box<dyn FnOnce(Option<HWND>) + Send + 'static>;

/// Posted to the owner window to wake the loop and drain the job queue.
const WM_RUN_JOBS: u32 = WM_APP + 1;

struct Worker {
    jobs: Sender<Job>,
    /// The message-only owner window, as an integer (`HWND` is not `Send`).
    hwnd: usize,
}

static WORKER: OnceLock<Result<Worker, String>> = OnceLock::new();

fn worker() -> Result<&'static Worker, ClipError> {
    WORKER
        .get_or_init(start_worker)
        .as_ref()
        .map_err(|e| ClipError::Platform(e.clone()))
}

fn start_worker() -> Result<Worker, String> {
    let (jobs_tx, jobs_rx) = channel::<Job>();
    let (ready_tx, ready_rx) = channel::<Result<usize, String>>();
    std::thread::Builder::new()
        .name("cfclip-clipboard".into())
        .spawn(move || clipboard_thread(jobs_rx, ready_tx))
        .map_err(|e| format!("failed to spawn clipboard thread: {e}"))?;
    let hwnd = ready_rx
        .recv()
        .map_err(|_| "clipboard thread exited during startup".to_string())??;
    Ok(Worker {
        jobs: jobs_tx,
        hwnd,
    })
}

fn clipboard_thread(jobs: Receiver<Job>, ready: Sender<Result<usize, String>>) {
    // The predefined STATIC class needs no registration; as a message-only
    // window it is invisible and receives no broadcasts.
    let hwnd = match unsafe {
        CreateWindowExW(
            WINDOW_EX_STYLE(0),
            w!("STATIC"),
            w!("championforms_clipboard"),
            WINDOW_STYLE(0),
            0,
            0,
            0,
            0,
            Some(HWND_MESSAGE),
            None,
            None,
            None,
        )
    } {
        Ok(h) => h,
        Err(e) => {
            let _ = ready.send(Err(format!("CreateWindowExW failed: {e}")));
            return;
        }
    };
    let _ = ready.send(Ok(hwnd.0 as usize));

    let mut msg = MSG::default();
    loop {
        // 0 = WM_QUIT, -1 = error; neither is expected for this window.
        let r = unsafe { GetMessageW(&mut msg, None, 0, 0) };
        if r.0 <= 0 {
            break;
        }
        if msg.hwnd == hwnd && msg.message == WM_RUN_JOBS {
            // Drain everything queued so far. A later WM_RUN_JOBS may then
            // find the queue empty, which is harmless.
            while let Ok(job) = jobs.try_recv() {
                // A job must not take the thread down; each job reports its
                // own panics through `done` (see `submit`).
                let _ = catch_unwind(AssertUnwindSafe(|| job(Some(hwnd))));
            }
        } else {
            unsafe { DispatchMessageW(&msg) };
        }
    }
}

/// Runs `op` on the clipboard thread and passes its result to `done` there.
/// `done` is always called exactly once, including when the worker cannot
/// start or `op` panics.
fn submit<T: Send + 'static>(
    op: impl FnOnce(HWND) -> Result<T, ClipError> + Send + 'static,
    done: Done<T>,
) {
    let worker = match worker() {
        Ok(w) => w,
        Err(e) => return done(Err(e)),
    };
    let job: Job = Box::new(move |hwnd| {
        let result = match hwnd {
            Some(hwnd) => catch_unwind(AssertUnwindSafe(|| op(hwnd))).unwrap_or_else(|_| {
                Err(ClipError::Platform("panic in clipboard operation".into()))
            }),
            None => Err(ClipError::Unavailable(
                "the clipboard thread is not running".into(),
            )),
        };
        done(result);
    });
    if let Err(std::sync::mpsc::SendError(job)) = worker.jobs.send(job) {
        // The thread is gone, so nothing will run the job. It owns `done`;
        // run it here with `None` so `done` still fires (with an error).
        // Never pass a NULL HWND: OpenClipboard(NULL) would succeed.
        job(None);
        return;
    }
    let hwnd = HWND(worker.hwnd as *mut _);
    // If posting fails (the thread's queue is full, ~10k messages) the job
    // stays queued and runs on the next successful post.
    let _ = unsafe { PostMessageW(Some(hwnd), WM_RUN_JOBS, WPARAM(0), LPARAM(0)) };
}

// ---------------------------------------------------------------------------
// Open/close with retry
// ---------------------------------------------------------------------------

/// Closes the clipboard when dropped, so every exit path (including `?`
/// after `EmptyClipboard`) releases it.
struct OpenClipboardGuard;

impl Drop for OpenClipboardGuard {
    fn drop(&mut self) {
        let _ = unsafe { CloseClipboard() };
    }
}

/// Backoff between `OpenClipboard` attempts: another process (clipboard
/// managers, RDP, Office) can hold the clipboard briefly. ~105 ms total.
const OPEN_RETRY_DELAYS_MS: [u64; 5] = [5, 10, 20, 30, 40];

fn open_clipboard(hwnd: HWND) -> Result<OpenClipboardGuard, ClipError> {
    let mut last = None;
    for delay in std::iter::once(0).chain(OPEN_RETRY_DELAYS_MS) {
        if delay > 0 {
            std::thread::sleep(Duration::from_millis(delay));
        }
        match unsafe { OpenClipboard(Some(hwnd)) } {
            Ok(()) => return Ok(OpenClipboardGuard),
            Err(e) => last = Some(e),
        }
    }
    Err(ClipError::Unavailable(format!(
        "could not open the clipboard (held by another process?): {}",
        last.map(|e| e.to_string()).unwrap_or_default()
    )))
}

// ---------------------------------------------------------------------------
// Format ids
// ---------------------------------------------------------------------------

const NAME_HTML: &str = "HTML Format";
const NAME_RTF: &str = "Rich Text Format";
const NAME_PNG: &str = "PNG";
const NAME_GIF: &str = "GIF";

fn wide(s: &str) -> Vec<u16> {
    s.encode_utf16().chain(std::iter::once(0)).collect()
}

fn register(name: &str) -> Result<u32, ClipError> {
    let name_w = wide(name);
    // Safety: `name_w` is NUL-terminated and outlives the call.
    let id = unsafe { RegisterClipboardFormatW(PCWSTR(name_w.as_ptr())) };
    if id == 0 {
        Err(ClipError::Platform(format!(
            "RegisterClipboardFormatW({name:?}) failed: {}",
            windows::core::Error::from_thread()
        )))
    } else {
        Ok(id)
    }
}

fn format_id(format: &Format) -> Result<u32, ClipError> {
    match format {
        Format::PlainText => Ok(u32::from(CF_UNICODETEXT.0)),
        Format::Html => register(NAME_HTML),
        Format::Rtf => register(NAME_RTF),
        Format::Png => register(NAME_PNG),
        Format::Gif => register(NAME_GIF),
        Format::Files => Ok(u32::from(CF_HDROP.0)),
        Format::Custom(name) => register(name),
    }
}

/// Name of a registered format (ids 0xC000..=0xFFFF); `None` for
/// predefined formats and on failure.
fn format_name(id: u32) -> Option<String> {
    let mut buf = [0u16; 256];
    let n = unsafe { GetClipboardFormatNameW(id, &mut buf) };
    (n > 0).then(|| String::from_utf16_lossy(&buf[..n as usize]))
}

/// Maps a format on the clipboard back to a [`Format`], or `None` if it is
/// not one we expose.
fn format_from_id(id: u32) -> Option<Format> {
    if id == u32::from(CF_UNICODETEXT.0)
        || id == u32::from(CF_TEXT.0)
        || id == u32::from(CF_OEMTEXT.0)
    {
        return Some(Format::PlainText);
    }
    if id == u32::from(CF_HDROP.0) {
        return Some(Format::Files);
    }
    let name = format_name(id)?;
    match name.as_str() {
        NAME_HTML => Some(Format::Html),
        NAME_RTF => Some(Format::Rtf),
        NAME_PNG => Some(Format::Png),
        NAME_GIF => Some(Format::Gif),
        _ => looks_like_custom(&name).then_some(Format::Custom(name)),
    }
}

/// Heuristic for "a custom format we could have written".
///
/// Windows and other apps register many formats (`Ole Private Data`,
/// `DataObject`, `Shell IDList Array`, `Chromium Web Custom MIME Data
/// Format`, `application/x-moz-nativehtml`, `Art::GVML ClipFormat`, …) that
/// are not meaningful to Dart. We only report names shaped like
/// reverse-DNS / dotted identifiers, e.g. `ChampionForms.Data` or
/// `com.example.thing`: ASCII letters, digits and `._+-`, starting with a
/// letter, with at least two non-empty dot-separated segments. Reading a
/// custom format by name works regardless; this only filters
/// `availableFormats()`.
fn looks_like_custom(name: &str) -> bool {
    name.starts_with(|c: char| c.is_ascii_alphabetic())
        && name
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || matches!(b, b'.' | b'_' | b'+' | b'-'))
        && name.split('.').count() >= 2
        && name.split('.').all(|s| !s.is_empty())
        && Format::parse(&format!("custom:{name}")).is_some()
}

// ---------------------------------------------------------------------------
// Encoding
// ---------------------------------------------------------------------------

/// UTF-8 → UTF-16LE bytes with a NUL terminator (CF_UNICODETEXT).
fn utf8_to_utf16_nul(data: &[u8]) -> Vec<u8> {
    String::from_utf8_lossy(data)
        .encode_utf16()
        .chain(std::iter::once(0))
        .flat_map(u16::to_le_bytes)
        .collect()
}

/// UTF-16LE bytes → UTF-8, stopping at the first NUL (the HGLOBAL may be
/// larger than the string).
fn utf16_to_utf8(data: &[u8]) -> Vec<u8> {
    let units: Vec<u16> = data
        .chunks_exact(2)
        .map(|c| u16::from_le_bytes([c[0], c[1]]))
        .take_while(|&u| u != 0)
        .collect();
    String::from_utf16_lossy(&units).into_bytes()
}

fn trim_trailing_nuls(mut data: Vec<u8>) -> Vec<u8> {
    let len = data.iter().rposition(|&b| b != 0).map_or(0, |i| i + 1);
    data.truncate(len);
    data
}

/// Bytes to hand to `SetClipboardData` for `format`.
fn to_system(format: &Format, data: &[u8]) -> Vec<u8> {
    match format {
        Format::PlainText => utf8_to_utf16_nul(data),
        Format::Html => {
            let mut v = cf_html::encode(&String::from_utf8_lossy(data));
            v.push(0);
            v
        }
        // RTF is 7-bit text; NUL-terminate for readers that use strlen.
        Format::Rtf => {
            let mut v = data.to_vec();
            v.push(0);
            v
        }
        Format::Files => hdrop::encode(&decode_paths(data)),
        Format::Png | Format::Gif | Format::Custom(_) => data.to_vec(),
    }
}

/// Converts clipboard bytes back to the Rust-side representation; `None`
/// drops the entry (e.g. unparseable CF_HTML).
fn from_system(format: &Format, data: Vec<u8>) -> Option<Vec<u8>> {
    match format {
        Format::PlainText => Some(utf16_to_utf8(&data)),
        Format::Html => cf_html::decode(&data).map(String::into_bytes),
        Format::Rtf => Some(trim_trailing_nuls(data)),
        Format::Files => {
            let paths = hdrop::decode(&data)?;
            (!paths.is_empty()).then(|| encode_paths(&paths))
        }
        Format::Png | Format::Gif | Format::Custom(_) => Some(data),
    }
}

// ---------------------------------------------------------------------------
// HGLOBAL helpers
// ---------------------------------------------------------------------------

/// Copies `bytes` into a new movable HGLOBAL. The caller owns it until
/// `SetClipboardData` succeeds.
fn alloc_global(bytes: &[u8]) -> Result<HGLOBAL, ClipError> {
    // A zero-byte GlobalAlloc yields a discarded handle; allocate at least 1.
    let size = bytes.len().max(1);
    let h = unsafe { GlobalAlloc(GMEM_MOVEABLE, size) }
        .map_err(|e| ClipError::Platform(format!("GlobalAlloc({size}) failed: {e}")))?;
    let ptr = unsafe { GlobalLock(h) } as *mut u8;
    if ptr.is_null() {
        let _ = unsafe { GlobalFree(Some(h)) };
        return Err(ClipError::Platform("GlobalLock failed".into()));
    }
    // Safety: `ptr` points to at least `size >= bytes.len()` writable bytes
    // and cannot overlap `bytes`.
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), ptr, bytes.len());
        // GlobalUnlock "fails" with NO_ERROR when the lock count hits 0.
        let _ = GlobalUnlock(h);
    }
    Ok(h)
}

/// Copies the contents of a clipboard HGLOBAL. The handle stays owned by
/// the system (we must not free it) and is valid until CloseClipboard.
fn read_global(handle: HANDLE) -> Option<Vec<u8>> {
    let h = HGLOBAL(handle.0);
    let ptr = unsafe { GlobalLock(h) } as *const u8;
    if ptr.is_null() {
        return None;
    }
    let size = unsafe { GlobalSize(h) };
    // Safety: a locked HGLOBAL of `GlobalSize` bytes is readable at `ptr`.
    let data = unsafe { std::slice::from_raw_parts(ptr, size) }.to_vec();
    let _ = unsafe { GlobalUnlock(h) };
    Some(data)
}

// ---------------------------------------------------------------------------
// Operations (clipboard thread)
// ---------------------------------------------------------------------------

fn write_now(hwnd: HWND, entries: Entries) -> Result<(), ClipError> {
    // Resolve ids and encode before touching the clipboard, so a bad entry
    // doesn't leave it emptied.
    let prepared = entries
        .iter()
        .map(|(f, d)| Ok((format_id(f)?, to_system(f, d))))
        .collect::<Result<Vec<_>, ClipError>>()?;

    let _guard = open_clipboard(hwnd)?;
    unsafe { EmptyClipboard() }
        .map_err(|e| ClipError::Platform(format!("EmptyClipboard failed: {e}")))?;
    for (id, bytes) in prepared {
        let h = alloc_global(&bytes)?;
        // On success the system owns `h`; on failure we still do.
        if let Err(e) = unsafe { SetClipboardData(id, Some(HANDLE(h.0))) } {
            let _ = unsafe { GlobalFree(Some(h)) };
            return Err(ClipError::Platform(format!(
                "SetClipboardData({id}) failed: {e}"
            )));
        }
    }
    Ok(())
    // `_guard` drops here (and on every early return): CloseClipboard.
}

fn read_now(hwnd: HWND, formats: Vec<Format>) -> Result<Entries, ClipError> {
    let ids = formats
        .iter()
        .map(format_id)
        .collect::<Result<Vec<_>, ClipError>>()?;
    let _guard = open_clipboard(hwnd)?;
    let mut out = Entries::new();
    for (format, id) in formats.into_iter().zip(ids) {
        if unsafe { IsClipboardFormatAvailable(id) }.is_err() {
            continue;
        }
        let Ok(handle) = (unsafe { GetClipboardData(id) }) else {
            continue;
        };
        if let Some(data) = read_global(handle).and_then(|d| from_system(&format, d)) {
            out.push((format, data));
        }
    }
    Ok(out)
}

fn available_now(hwnd: HWND) -> Result<Vec<Format>, ClipError> {
    let _guard = open_clipboard(hwnd)?;
    let mut out: Vec<Format> = Vec::new();
    let mut id = 0;
    loop {
        id = unsafe { EnumClipboardFormats(id) };
        if id == 0 {
            break; // done (or error; GetLastError distinguishes, we don't care)
        }
        if let Some(f) = format_from_id(id)
            && !out.contains(&f)
        {
            out.push(f);
        }
    }
    Ok(out)
}

// ---------------------------------------------------------------------------
// platform.rs contract
// ---------------------------------------------------------------------------

pub fn write(entries: Entries, done: Done<()>) {
    submit(move |hwnd| write_now(hwnd, entries), done);
}

pub fn read(formats: Vec<Format>, done: Done<Entries>) {
    submit(move |hwnd| read_now(hwnd, formats), done);
}

pub fn available(done: Done<Vec<Format>>) {
    submit(available_now, done);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn utf16_round_trip_with_nul() {
        let s = "héllo 🎉";
        let w = utf8_to_utf16_nul(s.as_bytes());
        assert_eq!(&w[w.len() - 2..], &[0, 0]);
        let mut padded = w.clone();
        padded.extend_from_slice(&[b'x', 0, 0, 0]); // junk after the NUL
        assert_eq!(utf16_to_utf8(&padded), s.as_bytes());
    }

    #[test]
    fn custom_heuristic() {
        for ok in ["ChampionForms.Data", "com.example.thing", "a.b+json"] {
            assert!(looks_like_custom(ok), "{ok}");
        }
        for bad in [
            "DataObject",
            "Ole Private Data",
            "application/x-moz-nativehtml",
            "Art::GVML ClipFormat",
            ".NET",
            "a..b",
            "1.2",
        ] {
            assert!(!looks_like_custom(bad), "{bad}");
        }
    }

    #[test]
    fn files_are_cf_hdrop() {
        let paths = [r"C:\a b.mp4", r"C:\é.gif"];
        let sys = to_system(&Format::Files, &encode_paths(&paths));
        assert_eq!(hdrop::decode(&sys).unwrap(), paths);
        assert_eq!(
            from_system(&Format::Files, sys).unwrap(),
            encode_paths(&paths)
        );
        assert_eq!(from_system(&Format::Files, hdrop::encode(&[])), None);
    }

    #[test]
    fn rtf_nul_trimmed() {
        let sys = to_system(&Format::Rtf, b"{\\rtf1}");
        assert_eq!(from_system(&Format::Rtf, sys).unwrap(), b"{\\rtf1}");
    }
}
