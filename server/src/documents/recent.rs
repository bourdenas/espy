use serde::{Deserialize, Serialize};

/// Document type under 'users/{user_id}/recent/entries' that represents the
/// history of recent additions in user's library.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct Recent {
    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub entries: Vec<RecentEntry>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct RecentEntry {
    pub id: u64,
    pub name: String,
    pub added_timestamp: u64,
}
