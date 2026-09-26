//! Format <-> UTI mapping shared by the macOS and iOS backends (see the
//! mapping table in lib/src/ffi/ABI.md). Pure logic, `cargo test`ed.

use crate::format::Format;

pub const PLAIN_TEXT: &str = "public.utf8-plain-text";
pub const HTML: &str = "public.html";
pub const RTF: &str = "public.rtf";
pub const PNG: &str = "public.png";
/// Read-only: macOS apps (Preview, screenshots, many image editors) often
/// put only TIFF on the pasteboard. The macOS backend converts it to PNG.
pub const TIFF: &str = "public.tiff";

/// The pasteboard type a format is written to and read from.
pub fn uti_for(format: &Format) -> &str {
    match format {
        Format::PlainText => PLAIN_TEXT,
        Format::Html => HTML,
        Format::Rtf => RTF,
        Format::Png => PNG,
        Format::Custom(name) => name,
    }
}

/// Maps a pasteboard type back to a format, or `None` for types we don't
/// expose.
///
/// Every non-system type is reported as `custom:<type>`: a custom format is
/// stored under its bare name, so there is no way to tell "ours" from any
/// other application's private type, and hiding them would hide ours too.
/// System types (the `public.*` and `dyn.*` namespaces, Apple's own
/// `com.apple.*` types, the nspasteboard.org marker types used by clipboard
/// managers and legacy `NS…PboardType` names) are ignored unless mapped
/// above. Names with whitespace (e.g. `CorePasteboardFlavorType 0x…`) are
/// rejected by [`Format::parse`].
///
/// With `tiff_as_png`, `public.tiff` maps to [`Format::Png`] (the macOS
/// backend synthesizes PNG from it on read).
pub fn format_for(uti: &str, tiff_as_png: bool) -> Option<Format> {
    match uti {
        PLAIN_TEXT => Some(Format::PlainText),
        HTML => Some(Format::Html),
        RTF => Some(Format::Rtf),
        PNG => Some(Format::Png),
        TIFF if tiff_as_png => Some(Format::Png),
        _ if is_system(uti) => None,
        _ => Format::parse(&format!("custom:{uti}")),
    }
}

fn is_system(uti: &str) -> bool {
    const PREFIXES: [&str; 4] = ["public.", "dyn.", "com.apple.", "org.nspasteboard."];
    PREFIXES.iter().any(|p| uti.starts_with(p))
        || (uti.starts_with("NS") && uti.ends_with("PboardType"))
}

/// Maps pasteboard types to formats, dropping unknown ones and duplicates
/// while keeping the pasteboard's order.
pub fn formats_for<'a>(utis: impl IntoIterator<Item = &'a str>, tiff_as_png: bool) -> Vec<Format> {
    let mut out = Vec::new();
    for f in utis.into_iter().filter_map(|u| format_for(u, tiff_as_png)) {
        if !out.contains(&f) {
            out.push(f);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn standard_formats_round_trip() {
        for f in [Format::PlainText, Format::Html, Format::Rtf, Format::Png] {
            assert_eq!(format_for(uti_for(&f), false), Some(f));
        }
    }

    #[test]
    fn custom_is_bare_uti() {
        let f = Format::Custom("com.championforms.data".into());
        assert_eq!(uti_for(&f), "com.championforms.data");
        assert_eq!(format_for("com.championforms.data", false), Some(f));
    }

    #[test]
    fn ignores_system_and_legacy_types() {
        for uti in [
            "public.utf16-plain-text",
            "public.jpeg",
            "dyn.ah62d4rv4gu8yc6durvwwaznwmuuha2pxsvw0e55bsmwca7d3sbwu",
            "com.apple.webarchive",
            "org.nspasteboard.TransientType",
            "NSStringPboardType",
            "Apple HTML pasteboard type",
            "CorePasteboardFlavorType 0x75747874",
        ] {
            assert_eq!(format_for(uti, true), None, "{uti}");
        }
    }

    #[test]
    fn tiff_only_when_requested() {
        assert_eq!(format_for(TIFF, false), None);
        assert_eq!(format_for(TIFF, true), Some(Format::Png));
    }

    #[test]
    fn formats_for_dedups_in_order() {
        let got = formats_for(
            [
                HTML,
                "public.utf16-plain-text",
                PLAIN_TEXT,
                TIFF,
                PNG,
                "com.x.y",
                HTML,
            ],
            true,
        );
        assert_eq!(
            got,
            vec![
                Format::Html,
                Format::PlainText,
                Format::Png,
                Format::Custom("com.x.y".into())
            ]
        );
    }
}
