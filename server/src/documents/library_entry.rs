use crate::documents::Annotation;
use crate::documents::GameEntry;
use crate::documents::StoreEntry;
use serde::{Deserialize, Serialize};

/// Document type under 'users/{user_id}/library/{game_id}' that represents a
/// game entry in user's library that has been matched with an IGDB entry.
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
    pub fn new(game: GameEntry, store_entries: Vec<StoreEntry>, owned_versions: &[u64]) -> Self {
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
            store_entries: store_entries,
            owned_versions: owned_versions.to_vec(),
            user_data: None,
        }
    }
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct GameUserData {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tags: Vec<String>,
}
