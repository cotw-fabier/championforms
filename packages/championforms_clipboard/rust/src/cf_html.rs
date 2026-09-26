//! Windows "HTML Format" (CF_HTML) encoding and decoding.
//!
//! OS-independent so it can be unit-tested on any host; only the Windows
//! backend uses it at runtime.
//!
//! Spec: <https://learn.microsoft.com/en-us/windows/win32/dataxchg/html-clipboard-format>.
//! The payload is UTF-8: an ASCII header of `Key:Value` lines followed by
//! the HTML. All offsets in the header are BYTE offsets from the start of
//! the payload, not character offsets.
//!
//! The header layout follows super_clipboard's `format_conversions.dart`
//! (Copyright (c) 2022 Superlist, Matej Knopp and the contributors, MIT),
//! with the offsets widened to 10 digits as Chromium writes them.

/// Width of the zero-padded offset values. Fixed width keeps the header
/// length independent of the offsets, so it can be computed up front.
const OFFSET_DIGITS: usize = 10;

const START_MARKER: &str = "<!--StartFragment-->";
const END_MARKER: &str = "<!--EndFragment-->";

/// Builds a CF_HTML payload (without a trailing NUL; the Windows backend
/// appends one) around `html_fragment`.
///
/// If `html_fragment` is already a full document (it has a `<body>` tag),
/// the fragment markers go just inside `<body>`/`</body>`; otherwise the
/// fragment is wrapped in `<html><body>`. The fragment bytes themselves are
/// never altered, so decode(encode(x)) == x.
pub fn encode(html_fragment: &str) -> Vec<u8> {
    // (document prefix, fragment, document suffix)
    let (prefix, fragment, suffix): (String, &str, String) =
        match split_body(html_fragment) {
            Some((before, inner, after)) => (
                format!("{before}{START_MARKER}"),
                inner,
                format!("{END_MARKER}{after}"),
            ),
            None => (
                format!("<html>\r\n<body>\r\n{START_MARKER}"),
                html_fragment,
                format!("{END_MARKER}\r\n</body>\r\n</html>"),
            ),
        };

    let header_len = header(0, 0, 0, 0).len();
    let start_html = header_len;
    let start_fragment = start_html + prefix.len();
    let end_fragment = start_fragment + fragment.len();
    let end_html = end_fragment + suffix.len();

    let head = header(start_html, end_html, start_fragment, end_fragment);
    debug_assert_eq!(head.len(), header_len);

    let mut out = Vec::with_capacity(end_html);
    out.extend_from_slice(head.as_bytes());
    out.extend_from_slice(prefix.as_bytes());
    out.extend_from_slice(fragment.as_bytes());
    out.extend_from_slice(suffix.as_bytes());
    out
}

fn header(start_html: usize, end_html: usize, start_fragment: usize, end_fragment: usize) -> String {
    let w = OFFSET_DIGITS;
    format!(
        "Version:0.9\r\n\
         StartHTML:{start_html:0w$}\r\n\
         EndHTML:{end_html:0w$}\r\n\
         StartFragment:{start_fragment:0w$}\r\n\
         EndFragment:{end_fragment:0w$}\r\n"
    )
}

/// Splits a full document into (up to and including `<body …>`, body
/// contents, from `</body>` on). `None` when there is no `<body` tag.
fn split_body(doc: &str) -> Option<(&str, &str, &str)> {
    let lower = doc.to_ascii_lowercase(); // same byte offsets as `doc`
    let open = find_tag(&lower, "<body", 0)?;
    let open_end = open + lower[open..].find('>')? + 1;
    let close = lower.rfind("</body").filter(|&c| c >= open_end)?;
    Some((&doc[..open_end], &doc[open_end..close], &doc[close..]))
}

/// Finds `<name` followed by `>`, whitespace or `/` (so `<body` does not
/// match `<bodyfoo`).
fn find_tag(lower: &str, name: &str, from: usize) -> Option<usize> {
    let mut at = from;
    while let Some(i) = lower[at..].find(name) {
        let pos = at + i;
        match lower.as_bytes().get(pos + name.len()) {
            Some(b'>' | b'/') | Some(b' ' | b'\t' | b'\r' | b'\n') => return Some(pos),
            _ => at = pos + name.len(),
        }
    }
    None
}

#[derive(Default, Debug)]
struct Header {
    start_html: Option<i64>,
    end_html: Option<i64>,
    start_fragment: Option<i64>,
    end_fragment: Option<i64>,
    /// Byte offset of the first byte after the header lines.
    end: usize,
}

/// Parses the leading `Key:Value` lines. Tolerates CRLF, LF or lone CR line
/// endings, case differences in keys, surrounding whitespace, unknown keys
/// (`SourceURL`, `StartSelection`, …) and any number of digits (Excel
/// writes 9, Chromium 10, Word 10, others 8).
fn parse_header(bytes: &[u8]) -> Header {
    let mut h = Header::default();
    let mut pos = 0;
    while pos < bytes.len() {
        // The header ends where the markup begins.
        if bytes[pos] == b'<' {
            break;
        }
        let line_end = bytes[pos..]
            .iter()
            .position(|&b| b == b'\r' || b == b'\n')
            .map_or(bytes.len(), |i| pos + i);
        let line = String::from_utf8_lossy(&bytes[pos..line_end]);
        let Some((key, value)) = line.split_once(':') else {
            // Not a header line (and not markup): stop, but only if we've
            // seen something header-ish; otherwise it's not CF_HTML.
            break;
        };
        let value = value.trim();
        let num = || value.parse::<i64>().ok();
        match key.trim().to_ascii_lowercase().as_str() {
            "starthtml" => h.start_html = num(),
            "endhtml" => h.end_html = num(),
            "startfragment" => h.start_fragment = num(),
            "endfragment" => h.end_fragment = num(),
            _ => {}
        }
        // Skip the line terminator (\r\n, \n or \r).
        pos = line_end;
        if bytes.get(pos) == Some(&b'\r') {
            pos += 1;
        }
        if bytes.get(pos) == Some(&b'\n') {
            pos += 1;
        }
    }
    h.end = pos;
    h
}

/// A validated byte range into a payload of `len` bytes. `EndX` values
/// past the end are clamped (some writers count a trailing NUL or are off
/// by the line terminator); negative values (`-1` = "absent") are rejected.
fn range(start: Option<i64>, end: Option<i64>, len: usize) -> Option<(usize, usize)> {
    let start = usize::try_from(start?).ok()?;
    let end = usize::try_from(end?).ok()?.min(len);
    (start <= end).then_some((start, end))
}

/// Extracts the HTML fragment from a CF_HTML payload.
///
/// Order of preference:
/// 1. `StartFragment`/`EndFragment` byte offsets, when in range and they
///    slice valid UTF-8;
/// 2. the `<!--StartFragment-->`/`<!--EndFragment-->` markers (matched
///    case-insensitively, with optional whitespace inside the comment),
///    which also rescues writers that counted characters instead of bytes;
/// 3. the `<body>` contents of the `StartHTML`/`EndHTML` range (or of the
///    markup after the header);
/// 4. all markup after the header.
///
/// Returns `None` for an empty payload or one with no markup at all.
pub fn decode(bytes: &[u8]) -> Option<String> {
    // Trailing NUL terminator(s) are not part of the payload.
    let len = bytes.iter().rposition(|&b| b != 0).map_or(0, |i| i + 1);
    let bytes = &bytes[..len];
    if bytes.is_empty() {
        return None;
    }
    let h = parse_header(bytes);

    if let Some((s, e)) = range(h.start_fragment, h.end_fragment, len) {
        if s >= h.end {
            if let Ok(fragment) = std::str::from_utf8(&bytes[s..e]) {
                return Some(fragment.to_owned());
            }
        }
    }

    let html_range = range(h.start_html, h.end_html, len)
        .filter(|&(s, _)| s >= h.end)
        .unwrap_or((h.end, len));
    let html = String::from_utf8_lossy(&bytes[html_range.0..html_range.1]);
    if !html.contains('<') {
        return None;
    }

    if let Some(fragment) = between_markers(&html) {
        return Some(fragment.to_owned());
    }
    if let Some((_, inner, _)) = split_body(&html) {
        return Some(inner.to_owned());
    }
    Some(html.into_owned())
}

/// Text between `<!--StartFragment-->` and `<!--EndFragment-->`, tolerant of
/// case and whitespace inside the comment (`<!--StartFragment -->`,
/// `<!-- StartFragment -->`).
fn between_markers(html: &str) -> Option<&str> {
    let (_, start) = find_comment(html, "startfragment", 0)?;
    let (end, _) = find_comment(html, "endfragment", start)?;
    Some(&html[start..end])
}

/// Finds `<!--\s*name\s*-->` at or after `from`; returns (start, end) byte
/// offsets of the whole comment.
fn find_comment(html: &str, name: &str, from: usize) -> Option<(usize, usize)> {
    let lower = html.to_ascii_lowercase();
    let mut at = from;
    while let Some(i) = lower[at..].find("<!--") {
        let open = at + i;
        let body_start = open + 4;
        let close = body_start + lower[body_start..].find("-->")?;
        if lower[body_start..close].trim() == name {
            return Some((open, close + 3));
        }
        at = body_start;
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    fn offsets(payload: &[u8]) -> Header {
        parse_header(payload)
    }

    fn slice(payload: &[u8], s: Option<i64>, e: Option<i64>) -> &str {
        std::str::from_utf8(&payload[s.unwrap() as usize..e.unwrap() as usize]).unwrap()
    }

    #[test]
    fn encode_header_offsets_are_consistent() {
        let payload = encode("<b>hi</b>");
        let text = std::str::from_utf8(&payload).unwrap();
        assert!(text.starts_with("Version:0.9\r\nStartHTML:"));
        let h = offsets(&payload);
        assert_eq!(slice(&payload, h.start_fragment, h.end_fragment), "<b>hi</b>");
        assert_eq!(h.end_html.unwrap() as usize, payload.len());
        assert_eq!(h.start_html.unwrap() as usize, h.end);
        assert!(slice(&payload, h.start_html, h.end_html).starts_with("<html>"));
        assert!(text.contains("<!--StartFragment--><b>hi</b><!--EndFragment-->"));
    }

    #[test]
    fn encode_uses_zero_padded_fixed_width() {
        let text = String::from_utf8(encode("x")).unwrap();
        for line in text.lines().skip(1).take(4) {
            let (_, v) = line.split_once(':').unwrap();
            assert_eq!(v.len(), OFFSET_DIGITS, "{line}");
            assert!(v.bytes().all(|b| b.is_ascii_digit()));
        }
    }

    #[test]
    fn offsets_are_bytes_for_multibyte_utf8() {
        let fragment = "<p>héllo — 日本語 🎉</p>";
        assert_ne!(fragment.len(), fragment.chars().count());
        let payload = encode(fragment);
        let h = offsets(&payload);
        let (s, e) = (h.start_fragment.unwrap() as usize, h.end_fragment.unwrap() as usize);
        assert_eq!(e - s, fragment.len());
        assert_eq!(&payload[s..e], fragment.as_bytes());
        assert_eq!(decode(&payload).as_deref(), Some(fragment));
    }

    #[test]
    fn round_trips() {
        for f in [
            "",
            "plain",
            "<p>a</p>\n<p>b</p>",
            "<p>a</p>\r\n<p>b</p>",
            "<table><tr><td>1</td></tr></table>",
            "<span>emoji 👩‍👩‍👧 and ünïcödé</span>",
        ] {
            assert_eq!(decode(&encode(f)).as_deref(), Some(f), "{f:?}");
        }
    }

    #[test]
    fn encode_full_document_puts_markers_inside_body() {
        let doc = "<html><head><title>t</title></head><body class=\"x\"><p>hi</p></body></html>";
        let payload = encode(doc);
        let text = std::str::from_utf8(&payload).unwrap();
        assert!(text.contains("<body class=\"x\"><!--StartFragment--><p>hi</p><!--EndFragment--></body></html>"));
        assert_eq!(decode(&payload).as_deref(), Some("<p>hi</p>"));
        let h = offsets(&payload);
        assert_eq!(slice(&payload, h.start_html, h.end_html), text[h.end..].to_string());
    }

    #[test]
    fn body_tag_prefix_is_not_confused() {
        // `<bodyish>` is not `<body>`: wrap normally.
        let payload = encode("<bodyish>x</bodyish>");
        assert_eq!(decode(&payload).as_deref(), Some("<bodyish>x</bodyish>"));
        assert!(std::str::from_utf8(&payload).unwrap().contains("<html>\r\n<body>"));
    }

    #[test]
    fn decode_ignores_trailing_nuls() {
        let mut payload = encode("<i>x</i>");
        payload.extend_from_slice(&[0, 0]);
        assert_eq!(decode(&payload).as_deref(), Some("<i>x</i>"));
    }

    /// Captured shape of Chromium's CF_HTML (with SourceURL).
    #[test]
    fn decode_chrome_sample() {
        let html = "<html>\r\n<body>\r\n<!--StartFragment--><b>Chrome</b><!--EndFragment-->\r\n</body>\r\n</html>";
        let header_len = "Version:0.9\r\nStartHTML:0000000000\r\nEndHTML:0000000000\r\nStartFragment:0000000000\r\nEndFragment:0000000000\r\nSourceURL:https://example.com/\r\n".len();
        let sf = header_len + html.find("<b>").unwrap();
        let ef = header_len + html.find("<!--EndFragment").unwrap();
        let payload = format!(
            "Version:0.9\r\nStartHTML:{:010}\r\nEndHTML:{:010}\r\nStartFragment:{:010}\r\nEndFragment:{:010}\r\nSourceURL:https://example.com/\r\n{html}\0",
            header_len,
            header_len + html.len(),
            sf,
            ef
        );
        assert_eq!(decode(payload.as_bytes()).as_deref(), Some("<b>Chrome</b>"));
    }

    /// Word writes Version:1.0, 10-digit offsets, StartSelection/EndSelection,
    /// a long <head>, and markers with no whitespace.
    #[test]
    fn decode_word_style_sample() {
        let html = "<html xmlns:o=\"urn:schemas-microsoft-com:office:office\">\r\n<head>\r\n<meta charset=utf-8>\r\n<style>p{margin:0}</style>\r\n</head>\r\n<body lang=EN-US>\r\n<!--StartFragment--><p class=MsoNormal>Wörd</p><!--EndFragment-->\r\n</body>\r\n</html>";
        let hdr = |a: usize, b: usize, c: usize, d: usize| {
            format!("Version:1.0\r\nStartHTML:{a:010}\r\nEndHTML:{b:010}\r\nStartFragment:{c:010}\r\nEndFragment:{d:010}\r\nStartSelection:{c:010}\r\nEndSelection:{d:010}\r\n")
        };
        let hl = hdr(0, 0, 0, 0).len();
        let sf = hl + html.find("<p class").unwrap();
        let ef = hl + html.find("<!--EndFragment").unwrap();
        let payload = format!("{}{html}", hdr(hl, hl + html.len(), sf, ef));
        assert_eq!(
            decode(payload.as_bytes()).as_deref(),
            Some("<p class=MsoNormal>Wörd</p>")
        );
    }

    /// Excel writes 9-digit offsets and LF-only line endings in some builds.
    #[test]
    fn decode_excel_style_lf_and_nine_digits() {
        let html = "<html>\n<body>\n<table><!--StartFragment--><tr><td>1</td></tr><!--EndFragment--></table>\n</body>\n</html>";
        let hdr = |a: usize, b: usize, c: usize, d: usize| {
            format!("Version:1.0\nStartHTML:{a:09}\nEndHTML:{b:09}\nStartFragment:{c:09}\nEndFragment:{d:09}\n")
        };
        let hl = hdr(0, 0, 0, 0).len();
        let sf = hl + html.find("<tr>").unwrap();
        let ef = hl + html.find("<!--EndFragment").unwrap();
        let payload = format!("{}{html}", hdr(hl, hl + html.len(), sf, ef));
        assert_eq!(decode(payload.as_bytes()).as_deref(), Some("<tr><td>1</td></tr>"));
    }

    #[test]
    fn decode_falls_back_to_markers_when_offsets_are_wrong() {
        // Offsets counted in characters (a known bug in some writers) land
        // mid-codepoint, so the markers win.
        let html = "<html><body><!--StartFragment-->日本<!--EndFragment--></body></html>";
        let payload = format!(
            "Version:0.9\r\nStartHTML:0000000001\r\nEndHTML:0000009999\r\nStartFragment:0000000138\r\nEndFragment:0000000139\r\n{html}"
        );
        // Sanity: the bogus range really is invalid UTF-8.
        assert!(std::str::from_utf8(&payload.as_bytes()[138..139]).is_err());
        assert_eq!(decode(payload.as_bytes()).as_deref(), Some("日本"));
    }

    #[test]
    fn decode_markers_with_whitespace_and_case() {
        let payload = "Version:0.9\r\nStartHTML:-1\r\nEndHTML:-1\r\nStartFragment:-1\r\nEndFragment:-1\r\n<html><body><!-- StartFragment --><i>x</i><!--endfragment --></body></html>";
        assert_eq!(decode(payload.as_bytes()).as_deref(), Some("<i>x</i>"));
    }

    #[test]
    fn decode_dart_super_clipboard_style_marker() {
        // super_clipboard writes `<!--StartFragment -->` (with a space).
        let payload = "Version:0.9\r\nStartHTML:-1\r\nEndHTML:-1\r\nStartFragment:-1\r\nEndFragment:-1\r\n<html><body>\r\n<!--StartFragment --><u>y</u><!--EndFragment-->\r\n</body></html>";
        assert_eq!(decode(payload.as_bytes()).as_deref(), Some("<u>y</u>"));
    }

    #[test]
    fn decode_without_markers_uses_body() {
        let payload = "Version:0.9\r\nStartHTML:-1\r\nEndHTML:-1\r\nStartFragment:-1\r\nEndFragment:-1\r\n<html><body><p>z</p></body></html>";
        assert_eq!(decode(payload.as_bytes()).as_deref(), Some("<p>z</p>"));
    }

    #[test]
    fn decode_headerless_markup() {
        assert_eq!(decode(b"<p>raw</p>").as_deref(), Some("<p>raw</p>"));
    }

    #[test]
    fn decode_clamps_end_past_payload() {
        let mut payload = encode("<p>c</p>");
        // Drop the suffix so EndHTML exceeds the length; EndFragment still fits.
        let h = offsets(&payload);
        payload.truncate(h.end_fragment.unwrap() as usize);
        assert_eq!(decode(&payload).as_deref(), Some("<p>c</p>"));
    }

    #[test]
    fn decode_rejects_empty_and_non_html() {
        assert_eq!(decode(b""), None);
        assert_eq!(decode(b"\0\0"), None);
        assert_eq!(decode(b"Version:0.9\r\nStartHTML:-1\r\n"), None);
    }
}
