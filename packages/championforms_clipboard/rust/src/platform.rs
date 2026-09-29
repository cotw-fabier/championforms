//! The per-platform backend interface.
//!
//! Exactly one module implements it for the target OS; `lib.rs` calls it
//! through the re-exported `write`, `read` and `available` functions.
//!
//! Every function must call `done` exactly once, from any thread, and must
//! not block the calling thread waiting for the platform main thread (hop
//! with the platform's async dispatch instead).

use crate::format::Format;

/// Format + bytes. Text formats are UTF-8 on the Rust side of every API;
/// platform modules convert (e.g. to UTF-16 for CF_UNICODETEXT).
pub type Entries = Vec<(Format, Vec<u8>)>;

#[derive(Debug)]
pub enum ClipError {
    /// Bad input from Dart (maps to ABI status -1).
    InvalidArgument(String),
    /// The clipboard could not be opened / is unavailable (-2). The Apple
    /// pasteboards are always available, so only the other backends use it.
    #[cfg_attr(any(target_os = "macos", target_os = "ios"), allow(dead_code))]
    Unavailable(String),
    /// The platform call failed (-3).
    Platform(String),
}

impl ClipError {
    pub fn status(&self) -> i32 {
        match self {
            ClipError::InvalidArgument(_) => -1,
            ClipError::Unavailable(_) => -2,
            ClipError::Platform(_) => -3,
        }
    }

    pub fn message(&self) -> &str {
        match self {
            ClipError::InvalidArgument(m) | ClipError::Unavailable(m) | ClipError::Platform(m) => m,
        }
    }
}

pub type Done<T> = Box<dyn FnOnce(Result<T, ClipError>) + Send + 'static>;

#[cfg(any(target_os = "macos", target_os = "ios"))]
pub use crate::apple::{available, read, write};

#[cfg(target_os = "windows")]
pub use crate::windows::{available, read, write};

#[cfg(target_os = "linux")]
pub use crate::linux::{available, read, write};

#[cfg(not(any(
    target_os = "macos",
    target_os = "ios",
    target_os = "windows",
    target_os = "linux"
)))]
pub use crate::unsupported::{available, read, write};
