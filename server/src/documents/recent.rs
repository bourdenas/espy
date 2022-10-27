use serde::{Deserialize, Serialize};

use super::StoreEntry;

/// Document type under 'users/{user_id}/recent/entries' that represents the
/// history of recent additions in user's library.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Recent {
    // #[serde(default)]
    // #[serde(skip_serializing_if = "Vec::is_empty")]
    pub entries: Vec<RecentEntry>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct RecentEntry {
    pub library_entry_id: u64,
    pub store_entry: StoreEntry,
    pub added_timestamp: u64,
}
