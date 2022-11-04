use super::Annotation;
use crate::documents::{Collection, Company, GameEntry, StoreEntry};
use serde::{Deserialize, Serialize};
use std::fmt;

/// Document type under 'users/{user_id}/library_v2/{game_id}' that represents a
/// game entry in user's library that has been matched with an IGDB entry.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct LegacyLibraryEntry {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cover: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub release_date: Option<i64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub collections: Vec<Annotation>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub companies: Vec<Annotation>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub store_entries: Vec<StoreEntry>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub owned_versions: Vec<u64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user_data: Option<GameUserData>,
}

impl LibraryEntry {
    pub fn new(
        game: GameEntry,
        store_entries: Vec<StoreEntry>,
        owned_versions: Vec<u64>,
        user_data: Option<GameUserData>,
    ) -> Self {
        LibraryEntry {
            id: game.id,
            name: game.name,
            cover: match game.cover {
                Some(cover) => Some(cover.image_id),
                None => None,
            },
            release_date: game.release_date,
            collections: game.collections,
            companies: game.companies,
            store_entries,
            owned_versions,
            user_data,
        }
    }
}

impl fmt::Display for LibraryEntry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "LibraryEntry({}): '{}'", &self.id, &self.name)
    }
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct GameUserData {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tags: Vec<String>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct LibraryEntry {
    pub id: u64,
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cover: Option<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub release_date: Option<i64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub collections: Vec<Collection>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub companies: Vec<Company>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub store_entries: Vec<StoreEntry>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub owned_versions: Vec<u64>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user_data: Option<GameUserData>,
}
