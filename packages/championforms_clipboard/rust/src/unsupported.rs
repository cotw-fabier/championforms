//! Clipboard backend: unsupported. Stub — see platform.rs for the contract.
//! Targets without a native clipboard backend.

use crate::format::Format;
use crate::platform::{ClipError, Done, Entries};

fn unsupported() -> ClipError {
    ClipError::Unavailable("clipboard backend not implemented on this platform".into())
}

pub fn write(_entries: Entries, done: Done<()>) {
    done(Err(unsupported()));
}

pub fn read(_formats: Vec<Format>, done: Done<Entries>) {
    done(Err(unsupported()));
}

pub fn available(done: Done<Vec<Format>>) {
    done(Err(unsupported()));
}
