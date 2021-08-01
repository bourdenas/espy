use serde::{Deserialize, Serialize};

/// A document that represents user ownership of a title in a storefront.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct StoreEntry {
    pub id: i64,
    pub title: String,
    pub storefront_name: String,

    #[serde(skip_serializing_if = "String::is_empty")]
    pub url: String,

    #[serde(skip_serializing_if = "String::is_empty")]
    pub image: String,
}
