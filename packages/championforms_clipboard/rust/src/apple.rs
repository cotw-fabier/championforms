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
//! bytes on both sides of the ABI. GIF is `com.compuserve.gif`. A file list
//! (macOS only) is one `public.file-url` pasteboard item per file.
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
        let result =
            catch_unwind(AssertUnwindSafe(|| autoreleasepool(|_| body()))).unwrap_or_else(|_| {
                Err(ClipError::Platform(
                    "panic in the Apple clipboard backend".into(),
                ))
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
    use objc2::rc::Retained;
    use objc2::runtime::{AnyObject, ProtocolObject};
    use objc2_app_kit::{
        NSBitmapImageFileType, NSBitmapImageRep, NSBitmapImageRepPropertyKey, NSPasteboard,
        NSPasteboardItem, NSPasteboardWriting,
    };
    use objc2_foundation::{NSArray, NSData, NSDictionary, NSString, NSURL};

    use super::uti::{self, uti_for};
    use super::{is_text, utf8_text};
    use crate::format::{Format, decode_paths, encode_paths};
    use crate::platform::{ClipError, Entries};

    // Only `public.utf8-plain-text` is written for plain text, not the
    // legacy `NSStringPboardType`: NSPasteboardTypeString *is*
    // "public.utf8-plain-text" since macOS 10.6, and the pasteboard server
    // translates legacy type names for old readers automatically.

    pub fn write(entries: &Entries) -> Result<(), ClipError> {
        let pb = NSPasteboard::generalPasteboard();
        if let Some((_, paths)) = entries.iter().find(|(f, _)| *f == Format::Files) {
            return write_with_files(&pb, entries, &decode_paths(paths));
        }
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

    /// A file list needs one pasteboard item per file, so this path writes
    /// `NSPasteboardItem`s with `writeObjects:`. The first item carries the
    /// first file's `public.file-url` plus every other format, so readers
    /// that only look at the first item (as the legacy `dataForType:` API
    /// does) still see all of them; each further file gets its own item.
    /// The URL strings are `NSURL fileURLWithPath:`'s, the same value an
    /// `NSURL` writes for itself.
    fn write_with_files(
        pb: &NSPasteboard,
        entries: &Entries,
        paths: &[String],
    ) -> Result<(), ClipError> {
        if paths.is_empty() {
            return Err(ClipError::InvalidArgument("empty file list".into()));
        }
        let file_url = NSString::from_str(uti::FILE_URL);
        let mut items: Vec<Retained<NSPasteboardItem>> = Vec::with_capacity(paths.len());
        for (i, path) in paths.iter().enumerate() {
            let item = NSPasteboardItem::new();
            let url = NSURL::fileURLWithPath(&NSString::from_str(path));
            let Some(url) = url.absoluteString() else {
                return Err(ClipError::InvalidArgument(format!(
                    "not a usable file path: {path:?}"
                )));
            };
            if !item.setString_forType(&url, &file_url) {
                return Err(ClipError::Platform(
                    "NSPasteboardItem setString:forType: failed for public.file-url".into(),
                ));
            }
            if i == 0 {
                for (format, bytes) in entries.iter().filter(|(f, _)| *f != Format::Files) {
                    let ty = NSString::from_str(uti_for(format));
                    if !item.setData_forType(&NSData::with_bytes(bytes), &ty) {
                        return Err(ClipError::Platform(format!(
                            "NSPasteboardItem setData:forType: failed for {}",
                            uti_for(format)
                        )));
                    }
                }
            }
            items.push(item);
        }
        let objects: Vec<Retained<ProtocolObject<dyn NSPasteboardWriting>>> = items
            .into_iter()
            .map(ProtocolObject::from_retained)
            .collect();
        pb.clearContents();
        if !pb.writeObjects(&NSArray::from_retained_slice(&objects)) {
            return Err(ClipError::Platform(
                "NSPasteboard writeObjects: failed".into(),
            ));
        }
        Ok(())
    }

    /// Every item's `public.file-url`, resolved to a path. Finder writes
    /// file reference URLs (`file:///.file/id=…`); `filePathURL` turns them
    /// into ordinary paths.
    fn read_files(pb: &NSPasteboard) -> Option<Vec<u8>> {
        let file_url = NSString::from_str(uti::FILE_URL);
        let items = pb.pasteboardItems()?;
        let paths: Vec<String> = items
            .iter()
            .filter_map(|item| {
                let s = item.stringForType(&file_url)?;
                let url = NSURL::URLWithString(&s)?;
                if !url.isFileURL() {
                    return None;
                }
                let path = url.filePathURL()?.path()?;
                Some(path.to_string())
            })
            .collect();
        (!paths.is_empty()).then(|| encode_paths(&paths))
    }

    fn read_one(pb: &NSPasteboard, format: &Format) -> Option<Vec<u8>> {
        if *format == Format::Files {
            return read_files(pb);
        }
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

    /// Uses a private uniquely named pasteboard, so the user's clipboard is
    /// left alone.
    #[cfg(test)]
    mod tests {
        use super::*;

        const PNG_1X1: [u8; 70] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48,
            0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00,
            0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78,
            0xDA, 0x63, 0x64, 0x60, 0xF8, 0x5F, 0x0F, 0x00, 0x02, 0x87, 0x01, 0x80, 0xEB, 0x47,
            0xBA, 0x92, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ];

        /// Frees the unique pasteboard in the pasteboard server (objc2 has
        /// no binding for `releaseGlobally`).
        fn release(pb: &NSPasteboard) {
            let _: () = unsafe { objc2::msg_send![pb, releaseGlobally] };
        }

        #[test]
        fn synthesizes_png_from_tiff() {
            let pb = NSPasteboard::pasteboardWithUniqueName();
            let rep = NSBitmapImageRep::imageRepWithData(&NSData::with_bytes(&PNG_1X1)).unwrap();
            let tiff = rep.TIFFRepresentation().unwrap();
            pb.clearContents();
            assert!(pb.setData_forType(Some(&tiff), &NSString::from_str(uti::TIFF)));

            let png = read_one(&pb, &Format::Png).expect("png synthesized");
            assert!(png.starts_with(&[0x89, b'P', b'N', b'G']));
            let back = NSBitmapImageRep::imageRepWithData(&NSData::with_bytes(&png)).unwrap();
            assert_eq!((back.pixelsWide(), back.pixelsHigh()), (1, 1));
            release(&pb);
        }

        #[test]
        fn files_round_trip_with_other_formats() {
            let pb = NSPasteboard::pasteboardWithUniqueName();
            // Non-ASCII letters come back decomposed (NFD): NSURL uses the
            // file system representation. The emoji has no decomposition.
            let paths = ["/tmp/championforms a.mp4", "/tmp/x😀#%.gif"];
            let gif = b"GIF89a\x01\x00\x01\x00".to_vec();
            let entries: Entries = vec![
                (Format::PlainText, b"two files".to_vec()),
                (Format::Gif, gif.clone()),
                (Format::Files, encode_paths(&paths)),
            ];
            write_with_files(&pb, &entries, &decode_paths(&entries[2].1)).unwrap();
            assert_eq!(pb.pasteboardItems().unwrap().len(), 2);
            let files = read_one(&pb, &Format::Files).expect("files read");
            assert_eq!(decode_paths(&files), paths);
            assert_eq!(read_one(&pb, &Format::Gif), Some(gif));
            assert_eq!(
                read_one(&pb, &Format::PlainText).as_deref(),
                Some(&b"two files"[..])
            );
            let names: Vec<String> = pb
                .types()
                .map(|t| t.iter().map(|t| t.to_string()).collect())
                .unwrap_or_default();
            let formats = uti::formats_for(names.iter().map(String::as_str), true);
            assert!(formats.contains(&Format::Files), "{names:?}");
            assert!(formats.contains(&Format::Gif), "{names:?}");
            release(&pb);
        }

        #[test]
        fn text_and_custom_bytes_round_trip() {
            let pb = NSPasteboard::pasteboardWithUniqueName();
            pb.clearContents();
            let text = "é😀".as_bytes();
            let custom = [0u8, 1, 0, 255];
            pb.setData_forType(
                Some(&NSData::with_bytes(text)),
                &NSString::from_str(uti::HTML),
            );
            pb.setData_forType(
                Some(&NSData::with_bytes(&custom)),
                &NSString::from_str("com.x.y"),
            );
            assert_eq!(read_one(&pb, &Format::Html).as_deref(), Some(text));
            assert_eq!(
                read_one(&pb, &Format::Custom("com.x.y".into())).as_deref(),
                Some(&custom[..])
            );
            assert_eq!(read_one(&pb, &Format::Rtf), None);
            release(&pb);
        }
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
        // Files never reach here (Dart's `supports` is false on iOS); skip
        // them if they do: UIPasteboard has no file references.
        for (format, bytes) in entries.iter().filter(|(f, _)| *f != Format::Files) {
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
        if *format == Format::Files {
            return None;
        }
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
        let mut formats = uti::formats_for(names.iter().map(String::as_str), false);
        formats.retain(|f| *f != Format::Files);
        formats
    }
}

#[cfg(test)]
mod tests {
    use super::utf8_text;

    #[test]
    fn keeps_utf8_bytes_exactly() {
        let bytes = "é😀<b>".as_bytes().to_vec();
        assert_eq!(
            utf8_text(Some(bytes.clone()), || panic!("no fallback")),
            Some(bytes)
        );
    }

    #[test]
    fn falls_back_for_utf16_and_invalid() {
        let utf16_bom = vec![0xFF, 0xFE, b'h', 0];
        let utf16_plain = vec![b'h', 0, b'i', 0];
        let latin1 = vec![b'c', b'a', b'f', 0xE9];
        for d in [utf16_bom, utf16_plain, latin1] {
            assert_eq!(
                utf8_text(Some(d), || Some("ok".into())),
                Some(b"ok".to_vec())
            );
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
