use crate::{
    api::FirestoreApi,
    documents::{GameEntry, LibraryEntry, Recent, RecentEntry, StoreEntry},
    Status,
};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::instrument;

pub struct LibraryOps;

impl LibraryOps {
    /// Write a `game_entry` and the associated `library_entry` on Firestore.
    ///
    /// The `library_entry` is updated with the input `game_entry` data but
    /// maintains existing user date (tags, store entries).
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_library_entry(
        firestore: &FirestoreApi,
        user_id: &str,
        library_entry: &LibraryEntry,
    ) -> Result<(), Status> {
        firestore.write(
            &format!("users/{user_id}/library_v2"),
            Some(&library_entry.id.to_string()),
            library_entry,
        )?;
        Ok(())
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn update_library_entry(
        firestore: &FirestoreApi,
        user_id: &str,
        library_entry: LibraryEntry,
    ) -> Result<(), Status> {
        let mut library_entry = library_entry;

        // Merge new LibraryEntry with existing one.
        if let Ok(existing) = firestore.read::<LibraryEntry>(
            &format!("users/{user_id}/library_v2"),
            &library_entry.id.to_string(),
        ) {
            library_entry
                .store_entries
                .extend(existing.store_entries.into_iter());
            library_entry
                .owned_versions
                .extend(existing.owned_versions.into_iter());
            library_entry.user_data = existing.user_data;
        }

        LibraryOps::write_library_entry(firestore, user_id, &library_entry)
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn remove_from_library_entry(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
        library_entry: &mut LibraryEntry,
    ) -> Result<(), Status> {
        // let mut library_entry = library_entry;
        library_entry.store_entries.retain(|entry| {
            entry.storefront_name != store_entry.storefront_name
                || entry.id != store_entry.id
                || entry.title != store_entry.title
        });

        if library_entry.store_entries.is_empty() {
            firestore.delete(&format!("users/{user_id}/library_v2/{}", library_entry.id))?;
        } else {
            LibraryOps::write_library_entry(firestore, user_id, &library_entry)?;
        }

        Ok(())
    }

    /// Returns a GameEntry doc based on `game_id` from Firestore.
    #[instrument(level = "trace", skip(firestore))]
    pub fn read_game_entry(firestore: &FirestoreApi, game_id: u64) -> Result<GameEntry, Status> {
        firestore.read::<GameEntry>("games_v2", &game_id.to_string())
    }

    /// Writes a GameEntry doc in Firestore.
    #[instrument(level = "trace", skip(firestore))]
    pub fn write_game_entry(
        firestore: &FirestoreApi,
        game_entry: &GameEntry,
    ) -> Result<(), Status> {
        firestore.write("games_v2", Some(&game_entry.id.to_string()), game_entry)?;
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
        library_entry: &LibraryEntry,
        store_entry: StoreEntry,
    ) -> Result<(), Status> {
        let mut recent = LibraryOps::read_recent(firestore, user_id);

        recent.entries.push(RecentEntry {
            library_entry_id: library_entry.id,
            store_entry: store_entry.clone(),
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
        storefront: StorefrontIds,
    ) -> Result<(), Status> {
        match firestore.write(
            &format!("users/{user_id}/storefronts"),
            Some(&storefront.name),
            &storefront,
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
        let mut storefront = firestore.read::<StorefrontIds>(
            &format!("users/{user_id}/storefront"),
            &store_entry.storefront_name,
        )?;

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

    /// Store store entry to user's unmatched collection.
    ///
    /// Writes `StoreEntry` documents under collection `users/{user}/unmatched`
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

    /// Store storefront entries to user's library under unmatched entries.
    ///
    /// Writes `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn write_failed(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        let mut title = String::default();
        if store_entry.id.is_empty() {
            title = safe_title(store_entry);
        }

        firestore.write(
            &format!("users/{user_id}/failed"),
            Some(&format!(
                "{}_{}",
                &store_entry.storefront_name,
                match store_entry.id.is_empty() {
                    false => &store_entry.id,
                    true => &title,
                },
            )),
            &store_entry,
        )?;

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
