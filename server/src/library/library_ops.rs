use crate::api::FirestoreApi;
use crate::documents::{GameEntry, LibraryEntry, Recent, RecentEntry, StoreEntry};
use crate::Status;
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct LibraryTransactions;

impl LibraryTransactions {
    /// Handles Firestore library updates on successful match of a StoreEntry.
    ///
    /// NOTE: The operations below should be a transaction, but this is not
    /// currently supported by this library.
    pub fn game_match(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        owned_version: u64,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        // Write GameEntry in games collection.
        LibraryOps::write_game(firestore, &game_entry)?;

        // Delete StoreEntry from unmatched.
        firestore.delete(&format!(
            "users/{user_id}/unmatched/{}_{}",
            store_entry.storefront_name, store_entry.id
        ))?;

        // Check if game is already in user's library.
        let mut library_entry = LibraryEntry::new(
            game_entry,
            vec![store_entry.clone()],
            vec![owned_version],
            None,
        );

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

        // Store (updated) LibraryEntry to Firestore.
        firestore.write(
            &format!("users/{user_id}/library_v2"),
            Some(&library_entry.id.to_string()),
            &library_entry,
        )?;

        LibraryOps::append_to_recent(firestore, user_id, &library_entry, store_entry)?;

        Ok(())
    }

    pub fn game_unmatch(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        library_entry: LibraryEntry,
        delete: bool,
    ) -> Result<(), Status> {
        let mut library_entry = library_entry;
        library_entry.store_entries.retain(|entry| {
            entry.storefront_name != store_entry.storefront_name && entry.id != store_entry.id
        });

        if library_entry.store_entries.is_empty() {
            firestore.delete(&format!("users/{user_id}/library_v2/{}", library_entry.id))?;
        } else {
            firestore.write(
                &format!("users/{user_id}/library_v2"),
                Some(&library_entry.id.to_string()),
                &library_entry,
            )?;
        }

        // Remove from recent collection.
        LibraryOps::remove_from_recent(firestore, user_id, &store_entry)?;

        if delete {
            LibraryOps::remove_from_storefront_ids(firestore, user_id, &store_entry)?;
        } else {
            // Write StoreEntry in failed collection.
            LibraryOps::write_failed(firestore, user_id, &store_entry)?;
        }

        Ok(())
    }

    /// Handles Firestore library updates on successful match of a StoreEntry.
    ///
    /// NOTE: The operations below should be a transaction, but this is not
    /// currently supported by this library.
    pub fn match_failed(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
    ) -> Result<(), Status> {
        // Delete StoreEntry from unmatched.
        firestore.delete(&format!(
            "users/{user_id}/unmatched/{}_{}",
            &store_entry.storefront_name, &store_entry.id
        ))?;

        // Write StoreEntry in failed.
        LibraryOps::write_failed(firestore, user_id, &store_entry)?;

        Ok(())
    }
}

pub struct LibraryOps;

impl LibraryOps {
    /// Returns user's game library entries.
    ///
    /// Reads `LibraryEntry` documents under collection
    /// `users/{user}/library_v2` in Firestore.
    pub fn list_library(
        firestore: &FirestoreApi,
        user_id: &str,
    ) -> Result<Vec<LibraryEntry>, Status> {
        firestore.list::<LibraryEntry>(&format!("users/{user_id}/library_v2"))
    }

    /// Returns a GameEntry doc based on `game_id` from Firestore.
    pub fn read_game(firestore: &FirestoreApi, game_id: u64) -> Result<GameEntry, Status> {
        firestore.read::<GameEntry>("games_v2", &game_id.to_string())
    }

    /// Writes a GameEntry doc in Firestore.
    pub fn write_game(firestore: &FirestoreApi, game_entry: &GameEntry) -> Result<(), Status> {
        firestore.write("games_v2", Some(&game_entry.id.to_string()), game_entry)?;
        Ok(())
    }

    fn read_recent(firestore: &FirestoreApi, user_id: &str) -> Recent {
        match firestore.read::<Recent>(&format!("users/{user_id}/recent"), "library_entries") {
            Ok(recent) => recent,
            Err(_) => Recent { entries: vec![] },
        }
    }

    fn append_to_recent(
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

    fn remove_from_recent(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        let mut recent = Self::read_recent(firestore, user_id);
        recent.entries.retain(|entry| {
            entry.store_entry.storefront_name != store_entry.storefront_name
                && entry.store_entry.id != store_entry.id
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
    pub fn read_storefront_ids(firestore: &FirestoreApi, user_id: &str, name: &str) -> Vec<String> {
        match firestore.read::<StorefrontIds>(&format!("users/{user_id}/storefronts"), name) {
            Ok(storefront) => storefront.owned_games,
            Err(_) => vec![],
        }
    }

    /// Writes all store game ids owned by user from specified storefront.
    ///
    /// Writes `users/{user}/storefront/{storefront_name}` document in
    /// Firestore.
    pub fn write_storefront_ids(
        firestore: &FirestoreApi,
        user_id: &str,
        storefront: StorefrontIds,
    ) -> Result<(), Status> {
        match firestore.write(
            &format!("users/{}/storefronts", user_id),
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
    fn remove_from_storefront_ids(
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

    /// Store storefront entries to user's library under unmatched entries.
    ///
    /// Writes `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    fn write_failed(
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

    /// Updates a `game_entry` and the associated `library_entry` on Firestore.
    ///
    /// The `library_entry` is updated with the input `game_entry` data but
    /// maintains existing user date (tags, store entries).
    pub fn update_library_entry(
        firestore: &FirestoreApi,
        user_id: &str,
        library_entry: LibraryEntry,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        // Store GameEntry to 'games' collection. Might overwrite an existing
        // one. That's ok as this is a fresher version.
        LibraryOps::write_game(firestore, &game_entry)?;

        // Store GameEntries to 'users/{user}/library_v2' collection.
        firestore.write(
            &format!("users/{user_id}/library_v2"),
            Some(&library_entry.id.to_string()),
            &LibraryEntry::new(
                game_entry,
                library_entry.store_entries,
                library_entry.owned_versions,
                library_entry.user_data,
            ),
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
