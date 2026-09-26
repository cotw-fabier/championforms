//! Clipboard backend for macOS (`NSPasteboard`) and iOS (`UIPasteboard`).
//!
//! Every operation runs on the main thread: inline when the caller is
//! already there (the Flutter UI isolate on macOS and iOS, where the
//! platform and UI threads are merged), otherwise hopped with
//! `dispatch_async` onto the main queue (background isolates). Nothing
//! blocks waiting for the main thread, so neither case can deadlock.
//!
//! Writes are eager: all formats are set up front, with no lazy
//! `NSPasteboardWriting` / item-provider callbacks. Text formats are UTF-8
//! bytes on both sides of the ABI.
//!
//! The TIFF-to-PNG synthesis and the "prefer the pasteboard's own string
//! conversion for text" approach follow super_native_extensions
//! (`darwin/macos/reader.rs`; Copyright (c) 2022 Superlist, Matej Knopp and
//! the contributors, MIT).

use std::panic::{AssertUnwindSafe, catch_unwind};

use dispatch2::DispatchQueue;
use objc2::rc::autoreleasepool;

use crate::format::Format;
use crate::platform::{ClipError, Done, Entries};

mod uti;

pub fn write(entries: Entries, done: Done<()>) {
    on_main(done, move || imp::write(&entries));
}

pub fn read(formats: Vec<Format>, done: Done<Entries>) {
    on_main(done, move || Ok(imp::read(&formats)));
}

pub fn available(done: Done<Vec<Format>>) {
    on_main(done, || Ok(imp::available()));
}

/// Runs `body` on the main thread (inline if already there, else
/// `dispatch_async`) inside an autorelease pool, and passes its result to
/// `done`. A panic in `body` becomes an error rather than unwinding through
/// libdispatch (which would abort).
fn on_main<T: Send + 'static>(
    done: Done<T>,
    body: impl FnOnce() -> Result<T, ClipError> + Send + 'static,
) {
    let task = move || {
        let result = catch_unwind(AssertUnwindSafe(|| autoreleasepool(|_| body())))
            .unwrap_or_else(|_| {
                Err(ClipError::Platform("panic in the Apple clipboard backend".into()))
            });
        done(result);
    };
    if unsafe { libc::pthread_main_np() } == 1 {
        task();
    } else {
        DispatchQueue::main().exec_async(task);
    }
}

fn is_text(format: &Format) -> bool {
    matches!(format, Format::PlainText | Format::Html | Format::Rtf)
}

/// Returns `data` when it looks like UTF-8 text, otherwise the pasteboard's
/// own string conversion (`fallback`) re-encoded as UTF-8. Other apps
/// sometimes publish text types in UTF-16 or a legacy encoding; the
/// pasteboard knows how to decode those, we don't. Our own writes are
/// UTF-8, so they come back byte for byte.
///
/// UTF-16 is often valid UTF-8 byte-wise (ASCII plus NULs), so a BOM or an
/// embedded NUL also counts as "not UTF-8 text".
fn utf8_text(data: Option<Vec<u8>>, fallback: impl FnOnce() -> Option<String>) -> Option<Vec<u8>> {
    let looks_utf8 = |d: &[u8]| {
        std::str::from_utf8(d).is_ok()
            && !d.starts_with(&[0xFE, 0xFF])
            && !d.starts_with(&[0xFF, 0xFE])
            && !d.contains(&0)
    };
    match data {
        Some(d) if looks_utf8(&d) => Some(d),
        data => fallback().map(String::into_bytes).or(data),
    }
}

#[cfg(target_os = "macos")]
mod imp {
    use objc2::runtime::AnyObject;
    use objc2_app_kit::{
        NSBitmapImageFileType, NSBitmapImageRep, NSBitmapImageRepPropertyKey, NSPasteboard,
    };
    use objc2_foundation::{NSData, NSDictionary, NSString};

    use super::uti::{self, uti_for};
    use super::{is_text, utf8_text};
    use crate::format::Format;
    use crate::platform::{ClipError, Entries};

    // Only `public.utf8-plain-text` is written for plain text, not the
    // legacy `NSStringPboardType`: NSPasteboardTypeString *is*
    // "public.utf8-plain-text" since macOS 10.6, and the pasteboard server
    // translates legacy type names for old readers automatically.

    pub fn write(entries: &Entries) -> Result<(), ClipError> {
        let pb = NSPasteboard::generalPasteboard();
        pb.clearContents();
        for (format, bytes) in entries {
            let ty = NSString::from_str(uti_for(format));
            if !pb.setData_forType(Some(&NSData::with_bytes(bytes)), &ty) {
                return Err(ClipError::Platform(format!(
                    "NSPasteboard setData:forType: failed for {}",
                    uti_for(format)
                )));
            }
        }
        Ok(())
    }

    pub fn read(formats: &[Format]) -> Entries {
        let pb = NSPasteboard::generalPasteboard();
        formats
            .iter()
            .filter_map(|f| read_one(&pb, f).map(|d| (f.clone(), d)))
            .collect()
    }

    fn read_one(pb: &NSPasteboard, format: &Format) -> Option<Vec<u8>> {
        let ty = NSString::from_str(uti_for(format));
        let data = pb.dataForType(&ty).map(|d| d.to_vec());
        match format {
            Format::Png => data.or_else(|| tiff_to_png(pb)),
            f if is_text(f) => utf8_text(data, || pb.stringForType(&ty).map(|s| s.to_string())),
            _ => data,
        }
    }

    /// Screenshots, Preview and many image apps put only `public.tiff` on
    /// the pasteboard; convert it so PNG readers still get an image.
    fn tiff_to_png(pb: &NSPasteboard) -> Option<Vec<u8>> {
        let tiff = pb.dataForType(&NSString::from_str(uti::TIFF))?;
        let rep = NSBitmapImageRep::imageRepWithData(&tiff)?;
        let props = NSDictionary::<NSBitmapImageRepPropertyKey, AnyObject>::new();
        // SAFETY: an empty properties dictionary has the correct type.
        let png =
            unsafe { rep.representationUsingType_properties(NSBitmapImageFileType::PNG, &props) }?;
        Some(png.to_vec())
    }

    pub fn available() -> Vec<Format> {
        let pb = NSPasteboard::generalPasteboard();
        let names: Vec<String> = pb
            .types()
            .map(|types| types.iter().map(|t| t.to_string()).collect())
            .unwrap_or_default();
        uti::formats_for(names.iter().map(String::as_str), true)
    }
}

#[cfg(target_os = "ios")]
mod imp {
    use objc2::rc::Retained;
    use objc2::runtime::{AnyObject, NSObject};
    use objc2_foundation::{NSArray, NSData, NSDictionary, NSString};
    use objc2_ui_kit::UIPasteboard;

    use super::uti::{self, uti_for};
    use super::{is_text, utf8_text};
    use crate::format::Format;
    use crate::platform::{ClipError, Entries};

    /// One item holding every format. Plain text and HTML are stored as
    /// `NSString` (what UIKit text views and most apps' `string` /
    /// `valueForPasteboardType:` readers expect); RTF, PNG and custom
    /// formats as `NSData`.
    pub fn write(entries: &Entries) -> Result<(), ClipError> {
        let pb = UIPasteboard::generalPasteboard();
        let mut keys: Vec<Retained<NSString>> = Vec::with_capacity(entries.len());
        let mut values: Vec<Retained<NSObject>> = Vec::with_capacity(entries.len());
        for (format, bytes) in entries {
            keys.push(NSString::from_str(uti_for(format)));
            let as_string = matches!(format, Format::PlainText | Format::Html);
            values.push(match std::str::from_utf8(bytes) {
                Ok(s) if as_string => Retained::into_super(NSString::from_str(s)),
                _ => Retained::into_super(NSData::with_bytes(bytes)),
            });
        }
        let key_refs: Vec<&NSString> = keys.iter().map(|k| &**k).collect();
        let value_refs: Vec<&AnyObject> = values.iter().map(|v| -> &AnyObject { v }).collect();
        let item = NSDictionary::<NSString, AnyObject>::from_slices(&key_refs, &value_refs);
        let items = NSArray::from_retained_slice(&[item]);
        // SAFETY: an array of dictionaries from type identifier to
        // NSString / NSData, as setItems: documents.
        unsafe { pb.setItems(&items) };
        Ok(())
    }

    pub fn read(formats: &[Format]) -> Entries {
        let pb = UIPasteboard::generalPasteboard();
        formats
            .iter()
            .filter_map(|f| read_one(&pb, f).map(|d| (f.clone(), d)))
            .collect()
    }

    fn read_one(pb: &UIPasteboard, format: &Format) -> Option<Vec<u8>> {
        let ty = NSString::from_str(uti_for(format));
        if !is_text(format) {
            return pb.dataForPasteboardType(&ty).map(|d| d.to_vec());
        }
        // Text may have been stored as NSString or NSData.
        let value = pb.valueForPasteboardType(&ty);
        if let Some(s) = value.as_deref().and_then(|v| v.downcast_ref::<NSString>()) {
            return Some(s.to_string().into_bytes());
        }
        let data = value
            .as_deref()
            .and_then(|v| v.downcast_ref::<NSData>())
            .map(|d| d.to_vec())
            .or_else(|| pb.dataForPasteboardType(&ty).map(|d| d.to_vec()));
        utf8_text(data, || None)
    }

    pub fn available() -> Vec<Format> {
        let pb = UIPasteboard::generalPasteboard();
        // SAFETY: called on the main thread (see `on_main`).
        let types = unsafe { pb.pasteboardTypes() };
        let names: Vec<String> = types.iter().map(|t| t.to_string()).collect();
        uti::formats_for(names.iter().map(String::as_str), false)
    }
}

#[cfg(test)]
mod tests {
    use super::utf8_text;

    #[test]
    fn keeps_utf8_bytes_exactly() {
        let bytes = "é😀<b>".as_bytes().to_vec();
        assert_eq!(utf8_text(Some(bytes.clone()), || panic!("no fallback")), Some(bytes));
    }

    #[test]
    fn falls_back_for_utf16_and_invalid() {
        let utf16_bom = vec![0xFF, 0xFE, b'h', 0];
        let utf16_plain = vec![b'h', 0, b'i', 0];
        let latin1 = vec![b'c', b'a', b'f', 0xE9];
        for d in [utf16_bom, utf16_plain, latin1] {
            assert_eq!(utf8_text(Some(d), || Some("ok".into())), Some(b"ok".to_vec()));
        }
    }

    #[test]
    fn keeps_raw_data_when_no_fallback() {
        let latin1 = vec![b'c', 0xE9];
        assert_eq!(utf8_text(Some(latin1.clone()), || None), Some(latin1));
        assert_eq!(utf8_text(None, || Some("s".into())), Some(b"s".to_vec()));
        assert_eq!(utf8_text(None, || None), None);
    }
}
