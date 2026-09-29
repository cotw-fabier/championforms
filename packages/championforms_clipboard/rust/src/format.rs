//! Platform-neutral clipboard format ids (see lib/src/ffi/ABI.md).
//!
//! Each platform module maps a [`Format`] to its own identifier.

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum Format {
    PlainText,
    Html,
    Rtf,
    Png,
    Gif,
    /// Local file paths. On the ABI the data is the UTF-8 paths joined by
    /// NUL bytes ([`encode_paths`] / [`decode_paths`]).
    Files,
    /// `custom:<name>`; holds `<name>`.
    Custom(String),
}

impl Format {
    pub fn parse(id: &str) -> Option<Format> {
        match id {
            "text/plain" => Some(Format::PlainText),
            "text/html" => Some(Format::Html),
            "text/rtf" => Some(Format::Rtf),
            "image/png" => Some(Format::Png),
            "image/gif" => Some(Format::Gif),
            "files" => Some(Format::Files),
            _ => {
                let name = id.strip_prefix("custom:")?;
                (!name.is_empty() && !name.contains(char::is_whitespace))
                    .then(|| Format::Custom(name.to_owned()))
            }
        }
    }

    pub fn id(&self) -> String {
        match self {
            Format::PlainText => "text/plain".into(),
            Format::Html => "text/html".into(),
            Format::Rtf => "text/rtf".into(),
            Format::Png => "image/png".into(),
            Format::Gif => "image/gif".into(),
            Format::Files => "files".into(),
            Format::Custom(name) => format!("custom:{name}"),
        }
    }
}

/// The ABI encoding of a file list: UTF-8 paths separated by NUL.
#[cfg_attr(target_os = "ios", allow(dead_code))]
pub fn encode_paths<S: AsRef<str>>(paths: &[S]) -> Vec<u8> {
    let mut out = Vec::new();
    for (i, p) in paths.iter().enumerate() {
        if i > 0 {
            out.push(0);
        }
        out.extend_from_slice(p.as_ref().as_bytes());
    }
    out
}

/// Inverse of [`encode_paths`]. Empty segments are dropped; invalid UTF-8 is
/// replaced rather than rejected.
#[cfg_attr(target_os = "ios", allow(dead_code))]
pub fn decode_paths(data: &[u8]) -> Vec<String> {
    data.split(|&b| b == 0)
        .filter(|s| !s.is_empty())
        .map(|s| String::from_utf8_lossy(s).into_owned())
        .collect()
}

/// `file://` URI for an absolute POSIX path, percent-encoding every byte
/// outside RFC 3986's unreserved set (and `/`). Used for `text/uri-list`.
#[cfg_attr(not(any(target_os = "linux", test)), allow(dead_code))]
pub fn path_to_file_uri(path: &str) -> String {
    let mut out = String::from("file://");
    for &b in path.as_bytes() {
        if b.is_ascii_alphanumeric() || matches!(b, b'/' | b'-' | b'.' | b'_' | b'~') {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
    out
}

/// The local path of a `file:` URI (`file:///p`, `file://localhost/p` or
/// `file:/p`), percent-decoded, or `None` for other schemes, remote hosts
/// and paths that do not decode to UTF-8.
#[cfg_attr(not(any(target_os = "linux", test)), allow(dead_code))]
pub fn file_uri_to_path(uri: &str) -> Option<String> {
    let uri = uri.trim();
    let scheme = uri.get(..5)?;
    if !scheme.eq_ignore_ascii_case("file:") {
        return None;
    }
    let rest = &uri[5..];
    let path = match rest.strip_prefix("//") {
        Some(after) => {
            let slash = after.find('/')?;
            let host = &after[..slash];
            if !(host.is_empty() || host.eq_ignore_ascii_case("localhost")) {
                return None;
            }
            &after[slash..]
        }
        None => rest,
    };
    if !path.starts_with('/') {
        return None;
    }
    // Drop any query or fragment, then percent-decode.
    let path = path.split(['?', '#']).next().unwrap_or(path);
    let bytes = path.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%'
            && let Some(hex) = path.get(i + 1..i + 3)
            && let Ok(b) = u8::from_str_radix(hex, 16)
        {
            decoded.push(b);
            i += 3;
        } else {
            decoded.push(bytes[i]);
            i += 1;
        }
    }
    let path = String::from_utf8(decoded).ok()?;
    (!path.contains('\0')).then_some(path)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips_ids() {
        for id in [
            "text/plain",
            "text/html",
            "text/rtf",
            "image/png",
            "image/gif",
            "files",
            "custom:com.x.y",
        ] {
            assert_eq!(Format::parse(id).unwrap().id(), id);
        }
    }

    #[test]
    fn rejects_unknown_and_malformed() {
        assert_eq!(Format::parse("text/csv"), None);
        assert_eq!(Format::parse("custom:"), None);
        assert_eq!(Format::parse("custom:has space"), None);
    }

    #[test]
    fn paths_round_trip() {
        let paths = ["/tmp/a b.mp4", "/Users/é/😀.gif"];
        let encoded = encode_paths(&paths);
        assert_eq!(encoded.iter().filter(|&&b| b == 0).count(), 1);
        assert_eq!(decode_paths(&encoded), paths);
        assert_eq!(decode_paths(b"\0/a\0\0/b\0"), ["/a", "/b"]);
        assert!(decode_paths(b"").is_empty());
    }

    #[test]
    fn file_uris_round_trip() {
        for p in ["/tmp/plain.txt", "/tmp/a b#c%d?.mp4", "/home/é/😀 x.gif"] {
            let uri = path_to_file_uri(p);
            assert!(uri.starts_with("file:///"), "{uri}");
            assert!(!uri.contains(' ') && !uri.contains('#'), "{uri}");
            assert_eq!(file_uri_to_path(&uri).as_deref(), Some(p));
        }
    }

    #[test]
    fn file_uri_forms() {
        assert_eq!(file_uri_to_path("file:///a/b").as_deref(), Some("/a/b"));
        assert_eq!(
            file_uri_to_path("FILE://localhost/a%20b").as_deref(),
            Some("/a b")
        );
        assert_eq!(file_uri_to_path("file:/a").as_deref(), Some("/a"));
        assert_eq!(file_uri_to_path("file://host/a"), None);
        assert_eq!(file_uri_to_path("https://x/a"), None);
        assert_eq!(file_uri_to_path("file://"), None);
        assert_eq!(file_uri_to_path("file:///a%00b"), None);
        assert_eq!(file_uri_to_path("fil"), None);
    }
}
