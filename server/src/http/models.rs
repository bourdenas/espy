use crate::documents;
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Upload {
    pub entries: Vec<documents::StoreEntry>,
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct Search {
    pub title: String,

    #[serde(default)]
    pub base_game_only: bool,
}

impl std::fmt::Display for Search {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.title)
    }
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Resolve {
    pub game_id: u64,
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Match {
    pub store_entry: documents::StoreEntry,
    pub game_entry: documents::GameEntry,
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Unmatch {
    pub store_entry: documents::StoreEntry,
    pub library_entry: documents::LibraryEntry,
    pub delete: bool,
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Rematch {
    pub store_entry: documents::StoreEntry,
    pub library_entry: documents::LibraryEntry,
    pub game_entry: documents::GameEntry,
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct WishlistOp {
    #[serde(default)]
    pub add_game: Option<documents::LibraryEntry>,

    #[serde(default)]
    pub remove_game: Option<u64>,
}
