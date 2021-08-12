use crate::documents;
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Match {
    pub store_entry: documents::StoreEntry,
    pub game_entry: documents::GameEntry,
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct Search {
    pub title: String,
}
