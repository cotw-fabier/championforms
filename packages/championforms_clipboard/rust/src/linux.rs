//! Clipboard backend: Linux (GTK3 `GtkClipboard`, hand-written FFI).
//!
//! See platform.rs for the contract. Every GTK call runs on the default
//! GLib main context (the Flutter/GTK main thread), reached with
//! `g_main_context_invoke(NULL, …)`: inline when the caller already owns
//! that context (the main thread), otherwise queued as an idle source.
//!
//! Writes are eager: the bytes are copied into a heap-allocated [`Owned`]
//! that GTK holds as `user_data` and serves from `get_func` whenever
//! another client asks; `clear_func` frees it when we lose ownership.
//! Reads are asynchronous (`gtk_clipboard_request_*` callbacks) and are
//! aggregated, with a timeout so `done` always fires.
//!
//! Target mapping (lib/src/ffi/ABI.md):
//! - `text/plain` → `text/plain;charset=utf-8`, `UTF8_STRING`, `TEXT`,
//!   `STRING` (served with `gtk_selection_data_set_text`, which converts
//!   for the legacy targets); read with `gtk_clipboard_request_text`, which
//!   negotiates the best text target itself.
//! - `text/html`  → `text/html`
//! - `text/rtf`   → `text/rtf`
//! - `image/png`  → `image/png`
//! - `custom:<n>` → `application/x-<n>`
//!
//! X11 vs Wayland: GTK3 abstracts both. On X11 the data lives in this
//! process and is lost when it exits unless a clipboard manager stores it
//! (we call `gtk_clipboard_set_can_store` so GTK hands it over on exit).
//! On Wayland, compositors only accept a new clipboard owner from a
//! surface that has keyboard focus / a recent input serial, so a write
//! from an unfocused window can be silently ignored even though
//! `gtk_clipboard_set_with_data` returns TRUE; reads from an unfocused
//! surface may likewise return nothing. Both are compositor policy.
//!
//! Callback plumbing adapted from super_native_extensions'
//! linux/clipboard_async.rs and linux/data_provider.rs (Copyright (c) 2022
//! Superlist, Matej Knopp and the contributors, MIT); gtk-rs, irondash and
//! lazy providers are dropped.
//!
//! ## Linking
//!
//! The extern blocks below carry `#[link(name = "gtk-3")]` etc. A Flutter
//! Linux app's runner executable already links libgtk-3 (and so
//! libgdk-3/libglib-2.0), and its DT_NEEDED libraries are in the global
//! symbol scope, so a cdylib dlopen'ed by Dart *could* resolve these
//! symbols without link attributes. We link explicitly anyway because:
//! - it is deterministic (no reliance on the host having loaded GTK, e.g.
//!   when the cdylib is loaded by `flutter test` or a pure-Dart host, where
//!   the failure would be a lazy-binding crash at the first GTK call);
//! - `cargo test`/test executables on Linux need resolved symbols at link
//!   time;
//! - it costs nothing: building a Flutter Linux app already requires
//!   `libgtk-3-dev` (it provides the unversioned `.so` symlinks), and at
//!   runtime the dynamic loader reuses the copy already mapped into the
//!   process, so there is never a second GTK instance.
//!
//! ## `unsafe` invariants
//!
//! - Every GTK/GDK call happens on the main-context thread (inside
//!   [`on_main`] or a GTK/GLib callback, which GTK invokes there).
//! - [`Owned`] is leaked with `Box::into_raw` into GTK and reclaimed exactly
//!   once: by `clear_func`, or by us if `gtk_clipboard_set_with_data`
//!   returns FALSE (GTK then never stores the callbacks or user_data).
//! - Each read callback owns one strong `Rc` (leaked with `Rc::into_raw`)
//!   and reclaims it exactly once when it fires. The timeout source owns
//!   one more, reclaimed by its `GDestroyNotify`, which GLib calls exactly
//!   once, whether the source fires or is removed by `g_source_remove`.
//!   A callback that never fires leaks its `Rc` (small, bounded) but cannot
//!   dangle; the timeout still completes the request.
//! - [`Req`] calls `done` at most once (it is `take()`n), and its `Drop`
//!   calls it if nothing else did (e.g. after a panic), so `done` is
//!   called exactly once unless the main loop never runs our closure.
//! - No panic unwinds across an `extern "C"` boundary: every callback body
//!   is wrapped in `catch_unwind`.

use std::cell::RefCell;
use std::ffi::{CStr, CString, c_char, c_int, c_uint, c_void};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::rc::Rc;

use crate::format::Format;
use crate::platform::{ClipError, Done, Entries};

// ---------------------------------------------------------------------------
// FFI
// ---------------------------------------------------------------------------

type Gboolean = c_int;
type Gpointer = *mut c_void;
/// `GdkAtom` is an opaque pointer (`struct _GdkAtom *`).
type GdkAtom = *mut c_void;

const GFALSE: Gboolean = 0;
const G_SOURCE_REMOVE: Gboolean = 0;
const G_PRIORITY_DEFAULT: c_int = 0;

#[repr(C)]
struct GtkClipboard {
    _private: [u8; 0],
}
#[repr(C)]
struct GtkSelectionData {
    _private: [u8; 0],
}
#[repr(C)]
struct GMainContext {
    _private: [u8; 0],
}

#[repr(C)]
struct GtkTargetEntry {
    target: *mut c_char,
    flags: c_uint,
    info: c_uint,
}

type GSourceFunc = Option<unsafe extern "C" fn(Gpointer) -> Gboolean>;
type GDestroyNotify = Option<unsafe extern "C" fn(Gpointer)>;
type GtkClipboardGetFunc =
    Option<unsafe extern "C" fn(*mut GtkClipboard, *mut GtkSelectionData, c_uint, Gpointer)>;
type GtkClipboardClearFunc = Option<unsafe extern "C" fn(*mut GtkClipboard, Gpointer)>;
type GtkClipboardReceivedFunc =
    Option<unsafe extern "C" fn(*mut GtkClipboard, *mut GtkSelectionData, Gpointer)>;
type GtkClipboardTextReceivedFunc =
    Option<unsafe extern "C" fn(*mut GtkClipboard, *const c_char, Gpointer)>;
type GtkClipboardTargetsReceivedFunc =
    Option<unsafe extern "C" fn(*mut GtkClipboard, *mut GdkAtom, c_int, Gpointer)>;

#[link(name = "gtk-3")]
unsafe extern "C" {
    fn gtk_clipboard_get(selection: GdkAtom) -> *mut GtkClipboard;
    fn gtk_clipboard_set_with_data(
        clipboard: *mut GtkClipboard,
        targets: *const GtkTargetEntry,
        n_targets: c_uint,
        get_func: GtkClipboardGetFunc,
        clear_func: GtkClipboardClearFunc,
        user_data: Gpointer,
    ) -> Gboolean;
    fn gtk_clipboard_set_can_store(
        clipboard: *mut GtkClipboard,
        targets: *const GtkTargetEntry,
        n_targets: c_int,
    );
    fn gtk_clipboard_request_contents(
        clipboard: *mut GtkClipboard,
        target: GdkAtom,
        callback: GtkClipboardReceivedFunc,
        user_data: Gpointer,
    );
    fn gtk_clipboard_request_text(
        clipboard: *mut GtkClipboard,
        callback: GtkClipboardTextReceivedFunc,
        user_data: Gpointer,
    );
    fn gtk_clipboard_request_targets(
        clipboard: *mut GtkClipboard,
        callback: GtkClipboardTargetsReceivedFunc,
        user_data: Gpointer,
    );
    fn gtk_selection_data_get_data(data: *const GtkSelectionData) -> *const u8;
    fn gtk_selection_data_get_length(data: *const GtkSelectionData) -> c_int;
    fn gtk_selection_data_get_target(data: *const GtkSelectionData) -> GdkAtom;
    fn gtk_selection_data_set(
        data: *mut GtkSelectionData,
        type_: GdkAtom,
        format: c_int,
        bytes: *const u8,
        length: c_int,
    );
    fn gtk_selection_data_set_text(
        data: *mut GtkSelectionData,
        str_: *const c_char,
        len: c_int,
    ) -> Gboolean;
}

#[link(name = "gdk-3")]
unsafe extern "C" {
    fn gdk_atom_intern(name: *const c_char, only_if_exists: Gboolean) -> GdkAtom;
    fn gdk_atom_intern_static_string(name: *const c_char) -> GdkAtom;
    fn gdk_atom_name(atom: GdkAtom) -> *mut c_char;
    fn gdk_display_get_default() -> *mut c_void;
}

#[link(name = "glib-2.0")]
unsafe extern "C" {
    fn g_main_context_invoke(context: *mut GMainContext, function: GSourceFunc, data: Gpointer);
    fn g_timeout_add_full(
        priority: c_int,
        interval: c_uint,
        function: GSourceFunc,
        data: Gpointer,
        notify: GDestroyNotify,
    ) -> c_uint;
    fn g_source_remove(tag: c_uint) -> Gboolean;
    fn g_free(mem: Gpointer);
}

// ---------------------------------------------------------------------------
// Main-context hop
// ---------------------------------------------------------------------------

type MainJob = Box<dyn FnOnce() + Send + 'static>;

/// Runs `f` on the default GLib main context (inline if we already own it).
fn on_main(f: impl FnOnce() + Send + 'static) {
    let job: Box<MainJob> = Box::new(Box::new(f));
    // Safety: `trampoline` reclaims the box exactly once. If the main loop
    // never runs again (process shutdown) the box leaks, which is fine.
    unsafe {
        g_main_context_invoke(
            std::ptr::null_mut(),
            Some(trampoline),
            Box::into_raw(job) as Gpointer,
        )
    };
}

unsafe extern "C" fn trampoline(data: Gpointer) -> Gboolean {
    let job = unsafe { Box::from_raw(data as *mut MainJob) };
    let _ = catch_unwind(AssertUnwindSafe(*job));
    G_SOURCE_REMOVE
}

/// The CLIPBOARD selection (not PRIMARY), or `None` without a display
/// (headless; `gtk_clipboard_get` would log a critical and return NULL).
fn clipboard() -> Option<*mut GtkClipboard> {
    unsafe {
        if gdk_display_get_default().is_null() {
            return None;
        }
        let cb = gtk_clipboard_get(gdk_atom_intern_static_string(c"CLIPBOARD".as_ptr()));
        (!cb.is_null()).then_some(cb)
    }
}

fn no_clipboard() -> ClipError {
    ClipError::Unavailable("no GTK display/clipboard available".into())
}

// ---------------------------------------------------------------------------
// Target mapping
// ---------------------------------------------------------------------------

const PLAIN_TARGETS: [&str; 4] = ["text/plain;charset=utf-8", "UTF8_STRING", "TEXT", "STRING"];

/// GTK targets offered for `format` when writing.
fn targets_for(format: &Format) -> Vec<String> {
    match format {
        Format::PlainText => PLAIN_TARGETS.iter().map(|s| s.to_string()).collect(),
        Format::Html => vec!["text/html".into()],
        Format::Rtf => vec!["text/rtf".into()],
        Format::Png => vec!["image/png".into()],
        Format::Custom(name) => vec![format!("application/x-{name}")],
    }
}

/// Maps an advertised target back to a [`Format`].
///
/// `application/x-<n>` is reported as `custom:<n>` for any `<n>` that is a
/// valid custom id, so other apps' private targets (e.g.
/// `application/x-moz-nativehtml`) show up too; Dart only acts on ids it
/// knows. `text/plain` and `COMPOUND_TEXT` count as plain text because
/// `gtk_clipboard_request_text` can read them.
fn format_for_target(target: &str) -> Option<Format> {
    match target {
        "text/plain;charset=utf-8"
        | "UTF8_STRING"
        | "TEXT"
        | "STRING"
        | "text/plain"
        | "COMPOUND_TEXT" => Some(Format::PlainText),
        "text/html" => Some(Format::Html),
        "text/rtf" => Some(Format::Rtf),
        "image/png" => Some(Format::Png),
        _ => Format::parse(&format!(
            "custom:{}",
            target.strip_prefix("application/x-")?
        )),
    }
}

fn trim_trailing_nuls(mut data: Vec<u8>) -> Vec<u8> {
    let len = data.iter().rposition(|&b| b != 0).map_or(0, |i| i + 1);
    data.truncate(len);
    data
}

/// `text/html` from some apps (older Firefox) is UTF-16 with a BOM;
/// normalise to UTF-8 and drop trailing NULs.
fn normalise_html(data: Vec<u8>) -> Vec<u8> {
    let utf16 = |bytes: &[u8], le: bool| {
        let units: Vec<u16> = bytes
            .chunks_exact(2)
            .map(|c| {
                if le {
                    u16::from_le_bytes([c[0], c[1]])
                } else {
                    u16::from_be_bytes([c[0], c[1]])
                }
            })
            .collect();
        String::from_utf16_lossy(&units).into_bytes()
    };
    let data = match data.as_slice() {
        [0xFF, 0xFE, rest @ ..] => utf16(rest, true),
        [0xFE, 0xFF, rest @ ..] => utf16(rest, false),
        _ => data,
    };
    trim_trailing_nuls(data)
}

// ---------------------------------------------------------------------------
// Write
// ---------------------------------------------------------------------------

/// Clipboard contents owned by GTK as `user_data` while we own the
/// selection. `GtkTargetEntry::info` indexes into `entries`.
struct Owned {
    entries: Entries,
}

unsafe extern "C" fn get_func(
    _clipboard: *mut GtkClipboard,
    selection: *mut GtkSelectionData,
    info: c_uint,
    user_data: Gpointer,
) {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        // Safety: `user_data` is the live `Owned` we registered; GTK only
        // calls get_func before clear_func.
        let owned = unsafe { &*(user_data as *const Owned) };
        let Some((format, data)) = owned.entries.get(info as usize) else {
            return;
        };
        let Ok(len) = c_int::try_from(data.len()) else {
            return; // > 2 GiB: cannot be expressed to GTK
        };
        // A non-null pointer even for empty data.
        let ptr = if data.is_empty() {
            b"".as_ptr()
        } else {
            data.as_ptr()
        };
        unsafe {
            if *format == Format::PlainText {
                // Converts to the requested target's encoding (STRING is
                // Latin-1, TEXT/COMPOUND_TEXT per ICCCM).
                gtk_selection_data_set_text(selection, ptr as *const c_char, len);
            } else {
                gtk_selection_data_set(
                    selection,
                    gtk_selection_data_get_target(selection),
                    8,
                    ptr,
                    len,
                );
            }
        }
    }));
}

unsafe extern "C" fn clear_func(_clipboard: *mut GtkClipboard, user_data: Gpointer) {
    // Safety: GTK calls clear_func exactly once for the user_data it
    // accepted, after which it never uses it again.
    let _ = catch_unwind(AssertUnwindSafe(|| {
        drop(unsafe { Box::from_raw(user_data as *mut Owned) })
    }));
}

fn write_now(entries: Entries) -> Result<(), ClipError> {
    let clipboard = clipboard().ok_or_else(no_clipboard)?;

    // The target strings only need to outlive the set_with_data call; GTK
    // interns them into atoms.
    let mut names: Vec<(CString, c_uint)> = Vec::new();
    for (i, (format, _)) in entries.iter().enumerate() {
        for t in targets_for(format) {
            let t = CString::new(t)
                .map_err(|_| ClipError::InvalidArgument("target contains NUL".into()))?;
            names.push((t, i as c_uint));
        }
    }
    if names.is_empty() {
        return Err(ClipError::InvalidArgument("no entries".into()));
    }
    let targets: Vec<GtkTargetEntry> = names
        .iter()
        .map(|(t, info)| GtkTargetEntry {
            target: t.as_ptr() as *mut c_char,
            flags: 0,
            info: *info,
        })
        .collect();

    let owned = Box::into_raw(Box::new(Owned { entries }));
    let ok = unsafe {
        gtk_clipboard_set_with_data(
            clipboard,
            targets.as_ptr(),
            targets.len() as c_uint,
            Some(get_func),
            Some(clear_func),
            owned as Gpointer,
        )
    };
    if ok == GFALSE {
        // GTK did not keep user_data or the callbacks; reclaim it.
        drop(unsafe { Box::from_raw(owned) });
        return Err(ClipError::Unavailable(
            "gtk_clipboard_set_with_data failed".into(),
        ));
    }
    // Let a clipboard manager keep the data after we exit (NULL = all targets).
    unsafe { gtk_clipboard_set_can_store(clipboard, std::ptr::null(), 0) };
    Ok(())
}

pub fn write(entries: Entries, done: Done<()>) {
    on_main(move || {
        let r = catch_unwind(AssertUnwindSafe(|| write_now(entries)))
            .unwrap_or_else(|_| Err(ClipError::Platform("panic in clipboard write".into())));
        done(r);
    });
}

// ---------------------------------------------------------------------------
// Async request aggregation (read / available)
// ---------------------------------------------------------------------------

/// How long a read may wait for the clipboard owner before failing. GTK's
/// own X11 selection timeout is much longer, and an owner that died may
/// never answer.
const TIMEOUT_MS: c_uint = 2000;

/// One pending read/available request. Lives in an `Rc<RefCell<…>>` on the
/// main thread, shared by its GTK callbacks and its timeout.
struct Req<A, T> {
    done: Option<Done<T>>,
    /// Source id of the timeout, 0 once it fired or was removed.
    timeout_id: c_uint,
    remaining: usize,
    /// `None` once taken on completion.
    acc: Option<A>,
    finish: fn(A) -> T,
}

type Shared<A, T> = Rc<RefCell<Req<A, T>>>;

impl<A, T> Drop for Req<A, T> {
    fn drop(&mut self) {
        // Only reachable with `done` still set if we bailed out (panic)
        // before completing; honour "done is always called".
        if let Some(done) = self.done.take() {
            done(Err(ClipError::Platform(
                "clipboard request abandoned".into(),
            )));
        }
    }
}

fn new_req<A: 'static, T: 'static>(
    done: Done<T>,
    remaining: usize,
    acc: A,
    finish: fn(A) -> T,
) -> Shared<A, T> {
    let req = Rc::new(RefCell::new(Req {
        done: Some(done),
        timeout_id: 0,
        remaining,
        acc: Some(acc),
        finish,
    }));
    // The timeout source owns one strong ref, released by `drop_rc`.
    let data = Rc::into_raw(req.clone()) as Gpointer;
    let id = unsafe {
        g_timeout_add_full(
            G_PRIORITY_DEFAULT,
            TIMEOUT_MS,
            Some(on_timeout::<A, T>),
            data,
            Some(drop_rc::<A, T>),
        )
    };
    req.borrow_mut().timeout_id = id;
    req
}

unsafe extern "C" fn drop_rc<A, T>(data: Gpointer) {
    // Safety: `data` came from `Rc::into_raw` in `new_req`; GLib calls the
    // destroy notify exactly once.
    let _ = catch_unwind(AssertUnwindSafe(|| {
        drop(unsafe { Rc::from_raw(data as *const RefCell<Req<A, T>>) })
    }));
}

unsafe extern "C" fn on_timeout<A, T>(data: Gpointer) -> Gboolean {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        // Borrow only; the reference is released by `drop_rc`.
        let req = unsafe { &*(data as *const RefCell<Req<A, T>>) };
        let done = {
            let mut r = req.borrow_mut();
            r.timeout_id = 0; // returning G_SOURCE_REMOVE removes it
            r.done.take()
        };
        if let Some(done) = done {
            done(Err(ClipError::Unavailable(
                "timed out waiting for the clipboard owner".into(),
            )));
        }
    }));
    G_SOURCE_REMOVE
}

/// Records one finished part; completes the request when it was the last.
/// Late parts (after a timeout) are ignored.
fn part_done<A, T>(req: &Shared<A, T>, record: impl FnOnce(&mut A)) {
    let (done, timeout, result) = {
        let mut r = req.borrow_mut();
        if r.done.is_none() {
            return;
        }
        let Some(acc) = r.acc.as_mut() else { return };
        record(acc);
        r.remaining -= 1;
        if r.remaining > 0 {
            return;
        }
        let Some(acc) = r.acc.take() else { return };
        let result = (r.finish)(acc);
        (
            r.done.take(),
            std::mem::replace(&mut r.timeout_id, 0),
            result,
        )
    };
    // Outside the borrow: removing the source runs `drop_rc` synchronously.
    if timeout != 0 {
        unsafe { g_source_remove(timeout) };
    }
    if let Some(done) = done {
        done(Ok(result));
    }
}

/// Per-callback user_data: one strong ref to the request plus the index of
/// the part it fills.
struct Part<A, T> {
    req: Shared<A, T>,
    index: usize,
}

fn leak_part<A, T>(req: &Shared<A, T>, index: usize) -> Gpointer {
    Box::into_raw(Box::new(Part {
        req: req.clone(),
        index,
    })) as Gpointer
}

/// Safety: `data` must come from `leak_part::<A, T>` and not have been
/// reclaimed; GTK invokes each request callback exactly once.
unsafe fn take_part<A, T>(data: Gpointer) -> Box<Part<A, T>> {
    unsafe { Box::from_raw(data as *mut Part<A, T>) }
}

// ---------------------------------------------------------------------------
// Read
// ---------------------------------------------------------------------------

/// One slot per requested format, in request order.
type ReadAcc = Vec<(Format, Option<Vec<u8>>)>;

fn finish_read(acc: ReadAcc) -> Entries {
    acc.into_iter().filter_map(|(f, d)| Some((f, d?))).collect()
}

fn convert_read(format: &Format, data: Vec<u8>) -> Vec<u8> {
    match format {
        Format::Html => normalise_html(data),
        Format::Rtf => trim_trailing_nuls(data),
        _ => data,
    }
}

unsafe extern "C" fn on_text(_: *mut GtkClipboard, text: *const c_char, data: Gpointer) {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        let part = unsafe { take_part::<ReadAcc, Entries>(data) };
        // `text` is UTF-8 (GTK converts), owned by GTK for this call only.
        let value = (!text.is_null()).then(|| unsafe { CStr::from_ptr(text) }.to_bytes().to_vec());
        part_done(&part.req, |acc| acc[part.index].1 = value);
    }));
}

unsafe extern "C" fn on_contents(
    _: *mut GtkClipboard,
    selection: *mut GtkSelectionData,
    data: Gpointer,
) {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        let part = unsafe { take_part::<ReadAcc, Entries>(data) };
        // Length < 0 means the owner did not provide this target. The
        // selection data is owned by GTK for this call only: copy it.
        let value = if selection.is_null() {
            None
        } else {
            let len = unsafe { gtk_selection_data_get_length(selection) };
            let ptr = unsafe { gtk_selection_data_get_data(selection) };
            match usize::try_from(len) {
                Ok(0) => Some(Vec::new()),
                Ok(len) if !ptr.is_null() => {
                    Some(unsafe { std::slice::from_raw_parts(ptr, len) }.to_vec())
                }
                _ => None,
            }
        };
        part_done(&part.req, |acc| {
            let slot = &mut acc[part.index];
            slot.1 = value.map(|v| convert_read(&slot.0, v));
        });
    }));
}

fn read_now(formats: Vec<Format>, done: Done<Entries>) {
    let Some(clipboard) = clipboard() else {
        return done(Err(no_clipboard()));
    };
    if formats.is_empty() {
        return done(Ok(Vec::new()));
    }
    // Resolve every target before issuing requests, so an error can't leave
    // a request half-issued. Plain text uses request_text (no atom).
    let mut atoms = Vec::with_capacity(formats.len());
    for f in &formats {
        let atom = if *f == Format::PlainText {
            std::ptr::null_mut()
        } else {
            let Ok(name) = CString::new(targets_for(f).remove(0)) else {
                return done(Err(ClipError::InvalidArgument(
                    "target contains NUL".into(),
                )));
            };
            unsafe { gdk_atom_intern(name.as_ptr(), GFALSE) }
        };
        atoms.push(atom);
    }

    let n = formats.len();
    let acc: ReadAcc = formats.iter().cloned().map(|f| (f, None)).collect();
    // The timeout is armed before the requests: callbacks can run
    // synchronously inside gtk_clipboard_request_* when this process owns
    // the clipboard.
    let req = new_req::<ReadAcc, Entries>(done, n, acc, finish_read);
    for (index, (format, atom)) in formats.iter().zip(atoms).enumerate() {
        let data = leak_part(&req, index);
        unsafe {
            if *format == Format::PlainText {
                gtk_clipboard_request_text(clipboard, Some(on_text), data);
            } else {
                gtk_clipboard_request_contents(clipboard, atom, Some(on_contents), data);
            }
        }
    }
    // Our local `req` drops here; the parts and the timeout keep it alive.
}

pub fn read(formats: Vec<Format>, done: Done<Entries>) {
    on_main(move || read_now(formats, done));
}

// ---------------------------------------------------------------------------
// Available
// ---------------------------------------------------------------------------

type AvailAcc = Vec<Format>;

fn finish_available(acc: AvailAcc) -> Vec<Format> {
    acc
}

unsafe extern "C" fn on_targets(
    _: *mut GtkClipboard,
    atoms: *mut GdkAtom,
    n_atoms: c_int,
    data: Gpointer,
) {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        let part = unsafe { take_part::<AvailAcc, Vec<Format>>(data) };
        let mut found: Vec<Format> = Vec::new();
        if !atoms.is_null() && n_atoms > 0 {
            // Safety: GTK passes `n_atoms` valid atoms, owned by GTK.
            for &atom in unsafe { std::slice::from_raw_parts(atoms, n_atoms as usize) } {
                let name = unsafe { gdk_atom_name(atom) };
                if name.is_null() {
                    continue;
                }
                let target = unsafe { CStr::from_ptr(name) }
                    .to_string_lossy()
                    .into_owned();
                unsafe { g_free(name as Gpointer) };
                if let Some(f) = format_for_target(&target)
                    && !found.contains(&f)
                {
                    found.push(f);
                }
            }
        }
        part_done(&part.req, |acc| *acc = found);
    }));
}

pub fn available(done: Done<Vec<Format>>) {
    on_main(move || {
        let Some(clipboard) = clipboard() else {
            return done(Err(no_clipboard()));
        };
        let req = new_req::<AvailAcc, Vec<Format>>(done, 1, Vec::new(), finish_available);
        let data = leak_part(&req, 0);
        unsafe { gtk_clipboard_request_targets(clipboard, Some(on_targets), data) };
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn targets_round_trip() {
        for f in [
            Format::PlainText,
            Format::Html,
            Format::Rtf,
            Format::Png,
            Format::Custom("championforms+json".into()),
        ] {
            for t in targets_for(&f) {
                assert_eq!(format_for_target(&t), Some(f.clone()), "{t}");
            }
        }
        assert_eq!(format_for_target("application/x-"), None);
        assert_eq!(format_for_target("TARGETS"), None);
    }

    #[test]
    fn html_utf16_bom_is_normalised() {
        let mut v = vec![0xFF, 0xFE];
        v.extend("<b>é</b>".encode_utf16().flat_map(u16::to_le_bytes));
        v.extend([0, 0]);
        assert_eq!(normalise_html(v), "<b>é</b>".as_bytes());
        assert_eq!(normalise_html(b"<i>x</i>\0".to_vec()), b"<i>x</i>");
    }
}
