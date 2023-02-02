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
pub struct MatchOp {
    /// The storefront entry that is {un}matched.
    pub store_entry: documents::StoreEntry,

    /// A game entry to match the storefront entry with, if one is provided.
    /// Usually, the storefront entry will be matched with the base game of this
    /// entry, unless `exact_match` is set to `true`.
    #[serde(default)]
    pub game_entry: Option<documents::GameEntry>,

    /// The library entry that the storefront entry will be unmatched from, if
    /// one is provided. The library entry will be also be deleted from the
    /// library if it contains no other storefront entry.
    #[serde(default)]
    pub unmatch_entry: Option<documents::LibraryEntry>,

    /// If true, matches the exact `game_entry` provided. Otherwise, it matches
    /// with the base game of provided `game_entry`.
    #[serde(default)]
    pub exact_match: bool,

    /// If true, deletes the store_entry from the library. Otherwise, it moves
    /// the store_entry to the failed-to-match collection, unless a rematch is
    /// provided.
    #[serde(default)]
    pub delete_unmatched: bool,
}

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct WishlistOp {
    #[serde(default)]
    pub add_game: Option<documents::LibraryEntry>,

    #[serde(default)]
    pub remove_game: Option<u64>,
}
