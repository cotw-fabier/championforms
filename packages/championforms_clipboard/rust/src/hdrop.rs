//! `CF_HDROP` payloads: a `DROPFILES` header followed by a double-NUL
//! terminated list of NUL-terminated paths.
//!
//! Pure byte handling, compiled on every target so `cargo test` covers it
//! on any host; only the Windows backend uses it. The layout follows
//! super_native_extensions' win32 `bundle_files` / `extract_drop_files`
//! (Copyright (c) 2022 Superlist, Matej Knopp and the contributors, MIT),
//! without the `DROPFILES` struct so it builds off Windows.
//!
//! ```c
//! typedef struct _DROPFILES {
//!   DWORD pFiles;  // offset of the file list from the start of the struct
//!   POINT pt;      // two LONGs, unused for the clipboard
//!   BOOL  fNC;
//!   BOOL  fWide;   // TRUE: the list is UTF-16LE, else ANSI
//! } DROPFILES;     // 20 bytes
//! ```

/// `sizeof(DROPFILES)`.
const HEADER_LEN: usize = 20;

/// A wide (`fWide = TRUE`) `CF_HDROP` payload for `paths`.
pub fn encode(paths: &[String]) -> Vec<u8> {
    let mut out = Vec::with_capacity(HEADER_LEN + 2);
    out.extend_from_slice(&(HEADER_LEN as u32).to_le_bytes()); // pFiles
    out.extend_from_slice(&0i32.to_le_bytes()); // pt.x
    out.extend_from_slice(&0i32.to_le_bytes()); // pt.y
    out.extend_from_slice(&0i32.to_le_bytes()); // fNC
    out.extend_from_slice(&1i32.to_le_bytes()); // fWide
    for p in paths {
        out.extend(
            p.encode_utf16()
                .chain(std::iter::once(0))
                .flat_map(u16::to_le_bytes),
        );
    }
    out.extend_from_slice(&[0, 0]);
    out
}

/// The paths in a `CF_HDROP` payload, or `None` when it is malformed. ANSI
/// (`fWide = FALSE`) lists are decoded as UTF-8 with replacement, which is
/// right for ASCII paths; nothing current writes ANSI lists.
pub fn decode(data: &[u8]) -> Option<Vec<String>> {
    let header = data.get(..HEADER_LEN)?;
    let word = |i: usize| -> Option<u32> {
        Some(u32::from_le_bytes(header.get(i..i + 4)?.try_into().ok()?))
    };
    let offset = usize::try_from(word(0)?).ok()?;
    let wide = word(16)? != 0;
    let list = data.get(offset..)?;
    let mut paths = Vec::new();
    if wide {
        let units: Vec<u16> = list
            .chunks_exact(2)
            .map(|c| u16::from_le_bytes([c[0], c[1]]))
            .collect();
        for segment in units.split(|&u| u == 0) {
            if segment.is_empty() {
                break;
            }
            paths.push(String::from_utf16_lossy(segment));
        }
    } else {
        for segment in list.split(|&b| b == 0) {
            if segment.is_empty() {
                break;
            }
            paths.push(String::from_utf8_lossy(segment).into_owned());
        }
    }
    Some(paths)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips_wide() {
        let paths = vec![r"C:\Users\é\clip 😀.mp4".to_string(), r"D:\a.gif".into()];
        let bytes = encode(&paths);
        assert_eq!(&bytes[..4], &[20, 0, 0, 0]);
        assert_eq!(&bytes[bytes.len() - 4..], &[0, 0, 0, 0]);
        assert_eq!(decode(&bytes), Some(paths));
    }

    #[test]
    fn decodes_ansi() {
        let mut bytes = vec![20, 0, 0, 0];
        bytes.extend([0; 16]); // pt, fNC, fWide = FALSE
        bytes.extend(b"C:\\a.txt\0C:\\b.txt\0\0");
        assert_eq!(
            decode(&bytes),
            Some(vec![r"C:\a.txt".to_string(), r"C:\b.txt".into()])
        );
    }

    #[test]
    fn rejects_short_and_bad_offsets() {
        assert_eq!(decode(&[0; 10]), None);
        let mut bytes = encode(&["x".into()]);
        bytes[0] = 200; // pFiles past the end
        assert_eq!(decode(&bytes), None);
        assert_eq!(decode(&encode(&[])), Some(vec![]));
    }
}
