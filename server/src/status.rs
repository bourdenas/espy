use reqwest;
use serde_json;
use std::{error::Error, fmt};
use tonic;

pub struct Status(tonic::Status);

impl Status {
    pub fn new(msg: impl Into<String>) -> Self {
        Self(tonic::Status::internal(msg))
    }

    pub fn internal(msg: &str, err: impl Error) -> Self {
        Self(tonic::Status::internal(format!("{}: '{}'", msg, err)))
    }

    pub fn invalid_argument(msg: &str) -> Self {
        Self(tonic::Status::invalid_argument(msg))
    }

    pub fn not_found(msg: &str) -> Self {
        Self(tonic::Status::not_found(msg))
    }
}

impl From<std::io::Error> for Status {
    fn from(err: std::io::Error) -> Self {
        Self(tonic::Status::from(err))
    }
}

impl From<tonic::Status> for Status {
    fn from(err: tonic::Status) -> Self {
        Self(err)
    }
}

impl From<serde_json::Error> for Status {
    fn from(err: serde_json::Error) -> Self {
        Self::new(format!("{err}"))
    }
}

impl From<reqwest::Error> for Status {
    fn from(err: reqwest::Error) -> Self {
        Self::new(format!("{err}"))
    }
}

impl Error for Status {}

impl fmt::Debug for Status {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(f)
    }
}

impl fmt::Display for Status {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(f)
    }
}
