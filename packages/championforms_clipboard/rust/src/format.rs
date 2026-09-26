//! Platform-neutral clipboard format ids (see lib/src/ffi/ABI.md).
//!
//! Each platform module maps a [`Format`] to its own identifier.

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum Format {
    PlainText,
    Html,
    Rtf,
    Png,
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
            Format::Custom(name) => format!("custom:{name}"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips_ids() {
        for id in ["text/plain", "text/html", "text/rtf", "image/png", "custom:com.x.y"] {
            assert_eq!(Format::parse(id).unwrap().id(), id);
        }
    }

    #[test]
    fn rejects_unknown_and_malformed() {
        assert_eq!(Format::parse("text/csv"), None);
        assert_eq!(Format::parse("custom:"), None);
        assert_eq!(Format::parse("custom:has space"), None);
    }
}
