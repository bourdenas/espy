use crate::documents::{self, StoreEntry};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct Search {
    pub title: String,
}

impl std::fmt::Display for Search {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.title)
    }
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Recon {
    pub store_entry: documents::StoreEntry,
    pub game_entry: documents::GameEntry,
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Upload {
    pub entries: Vec<StoreEntry>,
}
