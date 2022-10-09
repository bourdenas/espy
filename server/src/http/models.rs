use crate::documents;
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Recon {
    pub store_entry: documents::StoreEntry,
    pub game_entry: documents::GameEntry,
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct Search {
    pub title: String,
}

impl std::fmt::Display for Search {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.title)
    }
}
