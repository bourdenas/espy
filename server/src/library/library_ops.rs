use crate::{
    api::FirestoreApi,
    documents::{FailedEntries, GameEntry, Library, Recent, RecentEntry, StoreEntry, UserTags},
    Status,
};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::instrument;

pub struct LibraryOps;

impl LibraryOps {
    /// Returns a list of all games stored on espy Firestore.
    #[instrument(level = "trace", skip(firestore))]
    pub fn list_games(firestore: &FirestoreApi) -> Result<Vec<GameEntry>, Status> {
        firestore.list(&format!("games"))
    }

    /// Returns a GameEntry doc based on `game_id` from Firestore.
    #[instrument(level = "trace", skip(firestore))]
    pub fn read_game_entry(firestore: &FirestoreApi, game_id: u64) -> Result<GameEntry, Status> {
        firestore.read::<GameEntry>("games", &game_id.to_string())
    }

    /// Writes a GameEntry doc in Firestore.
    #[instrument(level = "trace", skip(firestore))]
    pub fn write_game_entry(
        firestore: &FirestoreApi,
        game_entry: &GameEntry,
    ) -> Result<(), Status> {
        firestore.write("games", Some(&game_entry.id.to_string()), game_entry)?;
        Ok(())
    }

    /// Returns a GameEntry doc based on `game_id` from Firestore.
    #[instrument(level = "trace", skip(firestore))]
    pub fn delete_game_entry(firestore: &FirestoreApi, game_id: u64) -> Result<(), Status> {
        firestore.delete(&format!("games/{}", game_id.to_string()))
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn read_library(firestore: &FirestoreApi, user_id: &str) -> Result<Library, Status> {
        firestore.read(&format!("users/{user_id}/games"), "library")
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_library(
        firestore: &FirestoreApi,
        user_id: &str,
        library: &Library,
    ) -> Result<(), Status> {
        firestore.write(&format!("users/{user_id}/games"), Some(&"library"), library)?;
        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn read_wishlist(firestore: &FirestoreApi, user_id: &str) -> Result<Library, Status> {
        firestore.read(&format!("users/{user_id}/games"), "wishlist")
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_wishlist(
        firestore: &FirestoreApi,
        user_id: &str,
        library: &Library,
    ) -> Result<(), Status> {
        firestore.write(&format!("users/{user_id}/games"), Some("wishlist"), library)?;
        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn read_user_tags(firestore: &FirestoreApi, user_id: &str) -> UserTags {
        match firestore.read::<UserTags>(&format!("users/{user_id}/user_data"), "tags") {
            Ok(tags) => tags,
            Err(_) => UserTags::new(),
        }
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_user_tags(
        firestore: &FirestoreApi,
        user_id: &str,
        user_tags: &UserTags,
    ) -> Result<(), Status> {
        firestore.write(
            &format!("users/{user_id}/user_data"),
            Some("tags"),
            user_tags,
        )?;

        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn add_user_tag(
        firestore: &FirestoreApi,
        user_id: &str,
        game_id: u64,
        tag_name: String,
        class_name: Option<&str>,
    ) -> Result<(), Status> {
        let mut user_tags = Self::read_user_tags(firestore, user_id);

        if user_tags.add(game_id, tag_name, class_name) {
            Self::write_user_tags(firestore, user_id, &user_tags)?;
        }
        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn remove_user_tag(
        firestore: &FirestoreApi,
        user_id: &str,
        game_id: u64,
        tag_name: &str,
        class_name: Option<&str>,
    ) -> Result<(), Status> {
        let mut user_tags = Self::read_user_tags(firestore, user_id);

        if user_tags.remove(game_id, tag_name, class_name) {
            Self::write_user_tags(firestore, user_id, &user_tags)?;
        }
        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn read_recent(firestore: &FirestoreApi, user_id: &str) -> Recent {
        match firestore.read::<Recent>(&format!("users/{user_id}/recent"), "library_entries") {
            Ok(recent) => recent,
            Err(_) => Recent { entries: vec![] },
        }
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn append_to_recent(
        firestore: &FirestoreApi,
        user_id: &str,
        library_entry_id: u64,
        store_entry: StoreEntry,
    ) -> Result<(), Status> {
        let mut recent = LibraryOps::read_recent(firestore, user_id);

        recent.entries.push(RecentEntry {
            library_entry_id,
            store_entry,
            added_timestamp: SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        });

        firestore.write(
            &format!("users/{user_id}/recent"),
            Some("library_entries"),
            &recent,
        )?;

        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn remove_from_recent(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        let mut recent = Self::read_recent(firestore, user_id);
        recent.entries.retain(|entry| {
            entry.store_entry.storefront_name != store_entry.storefront_name
                || entry.store_entry.id != store_entry.id
                || entry.store_entry.title != store_entry.title
        });

        firestore.write(
            &format!("users/{user_id}/recent"),
            Some("library_entries"),
            &recent,
        )?;

        Ok(())
    }

    /// Returns all store game ids owned by user from specified storefront.
    ///
    /// Reads `users/{user}/storefront/{storefront_name}` document in Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn read_storefront_ids(
        firestore: &FirestoreApi,
        user_id: &str,
        storefront: &str,
    ) -> Vec<String> {
        match firestore.read::<StorefrontIds>(&format!("users/{user_id}/storefronts"), storefront) {
            Ok(storefront) => storefront.owned_games,
            Err(_) => vec![],
        }
    }

    /// Writes all store game ids owned by user from specified storefront.
    ///
    /// Writes `users/{user}/storefront/{storefront_name}` document in
    /// Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_storefront_ids(
        firestore: &FirestoreApi,
        user_id: &str,
        storefront_name: &str,
        owned_games: Vec<String>,
    ) -> Result<(), Status> {
        match firestore.write(
            &format!("users/{user_id}/storefronts"),
            Some(storefront_name),
            &StorefrontIds {
                name: storefront_name.to_owned(),
                owned_games,
            },
        ) {
            Ok(_) => Ok(()),
            Err(e) => Err(Status::new("LibraryManager.write_storefront_ids: ", e)),
        }
    }

    /// Remove a StoreEntry from its StorefrontIds.
    ///
    /// Reads/writes `users/{user}/storefront/{storefront_name}` document in
    /// Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn remove_from_storefront_ids(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        let mut storefront = match firestore.read::<StorefrontIds>(
            &format!("users/{user_id}/storefront"),
            &store_entry.storefront_name,
        ) {
            Ok(storefront) => storefront,
            Err(_) => StorefrontIds {
                name: store_entry.storefront_name.clone(),
                ..Default::default()
            },
        };

        let index = storefront
            .owned_games
            .iter()
            .position(|id| *id == store_entry.id);

        if let Some(index) = index {
            storefront.owned_games.remove(index);
            firestore.write(
                &format!("users/{user_id}/storefront"),
                Some(&store_entry.storefront_name),
                &storefront,
            )?;
        }

        Ok(())
    }

    /// Returns StoreEntries from the unmatched collection in user's kibrary.
    ///
    /// Reads `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn list_unmatched(
        firestore: &FirestoreApi,
        user_id: &str,
    ) -> Result<Vec<StoreEntry>, Status> {
        firestore.list::<StoreEntry>(&format!("users/{user_id}/unmatched"))
    }

    /// Store store entry to user's unmatched collection.
    ///
    /// Writes `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_unmatched(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        let mut title = String::default();
        if store_entry.id.is_empty() {
            title = safe_title(store_entry);
        }

        firestore.write(
            &format!("users/{user_id}/unmatched"),
            Some(&format!(
                "{}_{}",
                &store_entry.storefront_name,
                match store_entry.id.is_empty() {
                    false => &store_entry.id,
                    true => &title,
                },
            )),
            store_entry,
        )?;

        Ok(())
    }

    /// Deletes store entry from user's unmatched collection.
    ///
    /// Deletes `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn delete_unmatched(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        let mut title = String::default();
        if store_entry.id.is_empty() {
            title = safe_title(store_entry);
        }

        firestore.delete(&format!(
            "users/{user_id}/unmatched/{}_{}",
            &store_entry.storefront_name,
            match store_entry.id.is_empty() {
                false => &store_entry.id,
                true => &title,
            },
        ))?;

        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn read_failed(firestore: &FirestoreApi, user_id: &str) -> Result<FailedEntries, Status> {
        firestore.read(&format!("users/{user_id}/games"), "failed")
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_failed(
        firestore: &FirestoreApi,
        user_id: &str,
        failed: &FailedEntries,
    ) -> Result<(), Status> {
        firestore.write(&format!("users/{user_id}/games"), Some("failed"), failed)?;
        Ok(())
    }
}

fn safe_title(store_entry: &StoreEntry) -> String {
    store_entry
        .title
        .replace(|c: char| !c.is_alphanumeric(), "_")
}

/// Document type under 'users/{user_id}/storefronts/{storefront_name}'. They
/// are used as a quick way to check user's game ownership in a storefront.
///
/// NOTE: Used as a duplicate entry, instead of querying GameEntries and
/// StoreEntries, to reduce Firestore reads when syncing libraries.
#[derive(Serialize, Deserialize, Default, Debug)]
pub struct StorefrontIds {
    pub name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub owned_games: Vec<String>,
}
