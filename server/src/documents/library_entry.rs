use serde::{Deserialize, Serialize};
use std::{
    fmt,
    time::{SystemTime, UNIX_EPOCH},
};

use super::{GameDigest, GameEntry, StoreEntry};

/// Document type under 'users/{user_id}/games/library' that includes user's
/// library with games matched with an IGDB entry.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Library {
    pub entries: Vec<LibraryEntry>,
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct LibraryEntry {
    pub id: u64,
    pub digest: GameDigest,
    pub parent_digest: Option<GameDigest>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub store_entries: Vec<StoreEntry>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub added_date: Option<u64>,
}

impl LibraryEntry {
    pub fn new(game: GameEntry, store_entries: Vec<StoreEntry>) -> Self {
        LibraryEntry {
            id: game.id,
            parent_digest: game.parent.clone(),
            digest: GameDigest::new(game),
            store_entries,

            added_date: Some(
                SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap()
                    .as_secs(),
            ),
        }
    }
}

impl fmt::Display for LibraryEntry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "LibraryEntry({}): '{}'", &self.id, &self.digest.name)
    }
}
