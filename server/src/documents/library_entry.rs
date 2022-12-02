use super::CompanyRole;
use crate::documents::{GameEntry, StoreEntry};
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use std::{cmp::Ordering, collections::HashSet, fmt};

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
    pub collections: Vec<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub companies: Vec<String>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub store_entries: Vec<StoreEntry>,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub owned_versions: Vec<u64>,
}

impl LibraryEntry {
    pub fn new(game: GameEntry, store_entries: Vec<StoreEntry>, owned_versions: Vec<u64>) -> Self {
        LibraryEntry {
            id: game.id,
            name: game.name,
            cover: match game.cover {
                Some(cover) => Some(cover.image_id),
                None => None,
            },
            release_date: game.release_date,

            collections: game
                .collections
                .iter()
                .map(|collection| collection.name.clone())
                .collect::<HashSet<_>>()
                .into_iter()
                .collect(),

            companies: game
                .companies
                .iter()
                .filter(|company| match company.role {
                    CompanyRole::Developer => true,
                    CompanyRole::Publisher => true,
                    _ => false,
                })
                .sorted_by(|l, r| match l.role {
                    CompanyRole::Developer => match r.role {
                        CompanyRole::Developer => Ordering::Equal,
                        _ => Ordering::Greater,
                    },
                    CompanyRole::Publisher => match r.role {
                        CompanyRole::Developer => Ordering::Less,
                        CompanyRole::Publisher => Ordering::Equal,
                        _ => Ordering::Greater,
                    },
                    _ => Ordering::Less,
                })
                .map(|company| company.name.clone())
                .collect::<HashSet<_>>()
                .into_iter()
                .collect(),

            store_entries,
            owned_versions,
        }
    }
}

impl fmt::Display for LibraryEntry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "LibraryEntry({}): '{}'", &self.id, &self.name)
    }
}
