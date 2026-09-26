//! championforms_clipboard native backend: eager multi-format clipboard
//! write/read with asynchronous completion. The C ABI is specified in
//! `lib/src/ffi/ABI.md`; this file only marshals between it and the
//! per-platform backend in `platform.rs`.
//!
//! Portions ported from super_native_extensions
//! (Copyright (c) 2022 Superlist, Matej Knopp and the contributors, MIT).
#![allow(clippy::missing_safety_doc)]

use std::cell::RefCell;
use std::ffi::{CStr, CString, c_char};
use std::panic::{AssertUnwindSafe, catch_unwind};

#[cfg_attr(not(target_os = "windows"), allow(dead_code))]
mod cf_html;
mod format;
mod platform;

#[cfg(any(target_os = "macos", target_os = "ios"))]
mod apple;
#[cfg(target_os = "linux")]
mod linux;
#[cfg(not(any(
    target_os = "macos",
    target_os = "ios",
    target_os = "windows",
    target_os = "linux"
)))]
mod unsupported;
#[cfg(target_os = "windows")]
mod windows;

use format::Format;
use platform::{ClipError, Entries};

#[repr(C)]
pub struct CfClipEntry {
    pub format: *const c_char,
    pub data: *const u8,
    pub len: usize,
}

pub type CfClipCallback =
    extern "C" fn(req_id: i64, status: i32, entries: *mut CfClipEntry, count: usize);

const STATUS_PANIC: i32 = -999;

thread_local! {
    static LAST_ERROR: RefCell<Option<String>> = const { RefCell::new(None) };
}

fn set_last_error(msg: impl Into<String>) {
    LAST_ERROR.with(|e| *e.borrow_mut() = Some(msg.into()));
}

/// Hands `entries` to Dart. Ownership passes to the Dart side, which
/// returns it through `cfclip_free_entries`.
fn complete(cb: CfClipCallback, req_id: i64, status: i32, entries: Vec<(String, Vec<u8>)>) {
    let mut raw: Vec<CfClipEntry> = entries
        .into_iter()
        .map(|(format, data)| {
            let format = CString::new(format).unwrap_or_default().into_raw();
            let (data, len) = if data.is_empty() {
                (std::ptr::null(), 0)
            } else {
                let boxed = data.into_boxed_slice();
                let len = boxed.len();
                (Box::into_raw(boxed) as *const u8, len)
            };
            CfClipEntry { format, data, len }
        })
        .collect();
    raw.shrink_to_fit();
    let count = raw.len();
    let ptr = if count == 0 {
        std::ptr::null_mut()
    } else {
        Box::into_raw(raw.into_boxed_slice()) as *mut CfClipEntry
    };
    cb(req_id, status, ptr, count);
}

fn complete_err(cb: CfClipCallback, req_id: i64, err: ClipError) {
    complete(cb, req_id, err.status(), vec![("error".into(), err.message().as_bytes().to_vec())]);
}

/// Runs `body`, converting panics and errors into an ABI status.
fn guarded(name: &str, body: impl FnOnce() -> Result<(), ClipError>) -> i32 {
    match catch_unwind(AssertUnwindSafe(body)) {
        Ok(Ok(())) => 0,
        Ok(Err(e)) => {
            set_last_error(e.message());
            e.status()
        }
        Err(_) => {
            set_last_error(format!("panic in {name}"));
            STATUS_PANIC
        }
    }
}

unsafe fn c_str(p: *const c_char, what: &str) -> Result<String, ClipError> {
    if p.is_null() {
        return Err(ClipError::InvalidArgument(format!("{what} is null")));
    }
    unsafe { CStr::from_ptr(p) }
        .to_str()
        .map(str::to_owned)
        .map_err(|_| ClipError::InvalidArgument(format!("{what} is not UTF-8")))
}

fn parse_format(id: &str) -> Result<Format, ClipError> {
    Format::parse(id).ok_or_else(|| ClipError::InvalidArgument(format!("unknown format id {id:?}")))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn cfclip_write(
    req_id: i64,
    entries: *const CfClipEntry,
    count: usize,
    cb: CfClipCallback,
) -> i32 {
    guarded("cfclip_write", || {
        if count == 0 || entries.is_null() {
            return Err(ClipError::InvalidArgument("no entries".into()));
        }
        let mut owned: Entries = Vec::with_capacity(count);
        for i in 0..count {
            let e = unsafe { &*entries.add(i) };
            let format = parse_format(&unsafe { c_str(e.format, "format") }?)?;
            let data = if e.len == 0 {
                Vec::new()
            } else if e.data.is_null() {
                return Err(ClipError::InvalidArgument("data is null".into()));
            } else {
                unsafe { std::slice::from_raw_parts(e.data, e.len) }.to_vec()
            };
            owned.push((format, data));
        }
        platform::write(
            owned,
            Box::new(move |r| match r {
                Ok(()) => complete(cb, req_id, 0, vec![]),
                Err(e) => complete_err(cb, req_id, e),
            }),
        );
        Ok(())
    })
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn cfclip_read(
    req_id: i64,
    formats: *const *const c_char,
    count: usize,
    cb: CfClipCallback,
) -> i32 {
    guarded("cfclip_read", || {
        if count > 0 && formats.is_null() {
            return Err(ClipError::InvalidArgument("formats is null".into()));
        }
        let mut wanted = Vec::with_capacity(count);
        for i in 0..count {
            wanted.push(parse_format(&unsafe { c_str(*formats.add(i), "format") }?)?);
        }
        platform::read(
            wanted,
            Box::new(move |r| match r {
                Ok(found) => complete(
                    cb,
                    req_id,
                    0,
                    found.into_iter().map(|(f, d)| (f.id(), d)).collect(),
                ),
                Err(e) => complete_err(cb, req_id, e),
            }),
        );
        Ok(())
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn cfclip_available_formats(req_id: i64, cb: CfClipCallback) -> i32 {
    guarded("cfclip_available_formats", || {
        platform::available(Box::new(move |r| match r {
            Ok(formats) => complete(
                cb,
                req_id,
                0,
                formats.into_iter().map(|f| (f.id(), Vec::new())).collect(),
            ),
            Err(e) => complete_err(cb, req_id, e),
        }));
        Ok(())
    })
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn cfclip_free_entries(entries: *mut CfClipEntry, count: usize) {
    if entries.is_null() {
        return;
    }
    let slice = unsafe { Box::from_raw(std::ptr::slice_from_raw_parts_mut(entries, count)) };
    for e in slice.iter() {
        if !e.format.is_null() {
            drop(unsafe { CString::from_raw(e.format as *mut c_char) });
        }
        if !e.data.is_null() {
            drop(unsafe {
                Box::from_raw(std::ptr::slice_from_raw_parts_mut(e.data as *mut u8, e.len))
            });
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cfclip_last_error() -> *mut c_char {
    LAST_ERROR.with(|e| match e.borrow_mut().take() {
        Some(s) => CString::new(s).unwrap_or_default().into_raw(),
        None => std::ptr::null_mut(),
    })
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn cfclip_free_string(s: *mut c_char) {
    if !s.is_null() {
        drop(unsafe { CString::from_raw(s) });
    }
}
