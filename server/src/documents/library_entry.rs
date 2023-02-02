use super::{CompanyRole, GameDigest};
use crate::documents::{GameEntry, StoreEntry};
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use std::{
    cmp::Ordering,
    collections::HashSet,
    fmt,
    time::{SystemTime, UNIX_EPOCH},
};

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

    #[serde(default)]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub added_date: Option<u64>,

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
            digest: GameDigest {
                name: game.name,
                cover: match game.cover {
                    Some(cover) => Some(cover.image_id),
                    None => None,
                },
                release_date: game.release_date,
                rating: game.igdb_rating,

                collections: game
                    .collections
                    .into_iter()
                    .map(|collection| collection.name)
                    .collect::<HashSet<_>>()
                    .into_iter()
                    .collect(),

                companies: game
                    .companies
                    .into_iter()
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
                    .map(|company| company.name)
                    .collect::<HashSet<_>>()
                    .into_iter()
                    .collect(),
            },

            added_date: Some(
                SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap()
                    .as_secs(),
            ),

            store_entries,
            owned_versions,
        }
    }
}

impl fmt::Display for LibraryEntry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "LibraryEntry({}): '{}'", &self.id, &self.digest.name)
    }
}
