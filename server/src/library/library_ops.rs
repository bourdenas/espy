use crate::api::FirestoreApi;
use crate::documents::{GameEntry, LibraryEntry, Recent, RecentEntry, StoreEntry};
use crate::Status;
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct LibraryOps {}

impl LibraryOps {
    /// Store storefront entries to user's library under unmatched entries.
    ///
    /// Writes `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    pub fn write_unmatched_entries(
        firestore: &FirestoreApi,
        user_id: &str,
        storefront_name: &str,
        entries: &[StoreEntry],
    ) -> Result<(), Status> {
        for entry in entries {
            firestore.write(
                &format!("users/{user_id}/unmatched"),
                Some(&format!("{storefront_name}_{}", entry.id)),
                entry,
            )?;
        }
        Ok(())
    }

    /// Read unmatched storefront entries in user's library.
    ///
    /// Reads `StoreEntry` documents under collection `users/{user}/unmatched`
    /// in Firestore.
    pub fn read_unmatched_entries(
        firestore: &FirestoreApi,
        user_id: &str,
    ) -> Result<Vec<StoreEntry>, Status> {
        match firestore.list::<StoreEntry>(&format!("users/{user_id}/unmatched")) {
            Ok(entries) => Ok(entries),
            Err(e) => Err(Status::new("LibraryManager.read_unmatched_entries: ", e)),
        }
    }

    /// Returns user's matched game library entries.
    ///
    /// Reads `LibraryEntry` documents under collection
    /// `users/{user}/library_v2` in Firestore.
    pub fn read_library_entries(
        firestore: &FirestoreApi,
        user_id: &str,
    ) -> Result<Vec<LibraryEntry>, Status> {
        match firestore.list::<LibraryEntry>(&format!("users/{user_id}/library_v2")) {
            Ok(entries) => Ok(entries),
            Err(e) => Err(Status::new("LibraryManager.read_library_entries: ", e)),
        }
    }

    /// Writes all store game ids owned by user from specified storefront.
    ///
    /// Writes `users/{user}/storefront/{storefront_name}` document in
    /// Firestore.
    pub fn write_storefront_ids(
        firestore: &FirestoreApi,
        user_id: &str,
        name: &str,
        ids: &[String],
    ) -> Result<(), Status> {
        match firestore.write(
            &format!("users/{}/storefronts", user_id),
            Some(name),
            &Storefront {
                name: String::from(name),
                owned_games: ids.to_vec(),
            },
        ) {
            Ok(_) => Ok(()),
            Err(e) => Err(Status::new("LibraryManager.write_storefront_ids: ", e)),
        }
    }

    /// Returns all store game ids owned by user from specified storefront.
    ///
    /// Reads `users/{user}/storefront/{storefront_name}` document in Firestore.
    pub fn read_storefront_ids(firestore: &FirestoreApi, user_id: &str, name: &str) -> Vec<String> {
        match firestore.read::<Storefront>(&format!("users/{user_id}/storefronts"), name) {
            Ok(storefront) => storefront.owned_games,
            Err(_) => vec![],
        }
    }

    /// Returns a GameEntry doc based on `game_id` from Firestore.
    pub fn read_game_entry(firestore: &FirestoreApi, game_id: u64) -> Result<GameEntry, Status> {
        firestore.read::<GameEntry>("games_v2", &game_id.to_string())
    }

    /// Writes a GameEntry doc in Firestore.
    pub fn write_game_entry(
        firestore: &FirestoreApi,
        game_entry: &GameEntry,
    ) -> Result<(), Status> {
        match firestore.write("games_v2", Some(&game_entry.id.to_string()), game_entry) {
            Ok(_) => Ok(()),
            Err(e) => Err(Status::new("LibraryManager.write_game_entry: ", e)),
        }
    }

    /// Handles Firestore library updates on successful match of a StoreEntry.
    ///
    /// NOTE: The operations below should be a transaction, but this is not
    /// currently supported by this library.
    pub fn game_match_transaction(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        owned_version: u64,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        // Write GameEntry in games collection.
        LibraryOps::write_game_entry(firestore, &game_entry)?;

        // Delete StoreEntry from unmatched.
        firestore.delete(&format!(
            "users/{user_id}/unmatched/{}_{}",
            store_entry.storefront_name, store_entry.id
        ))?;

        // Check if game is already in user's library.
        let mut library_entry =
            LibraryEntry::new(game_entry, vec![store_entry], vec![owned_version], None);

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

        // Update recent entries in Firestore.
        let recent_entry = RecentEntry {
            id: library_entry.id,
            name: library_entry.name,
            added_timestamp: SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };
        let recent =
            match firestore.read::<Recent>(&format!("users/{user_id}/recent"), "library_entries") {
                Ok(mut recent) => {
                    recent.entries.push(recent_entry);
                    recent
                }
                Err(_) => Recent {
                    entries: vec![recent_entry],
                },
            };

        firestore.write(
            &format!("users/{user_id}/recent"),
            Some("library_entries"),
            &recent,
        )?;

        Ok(())
    }

    /// Handles Firestore library updates on successful match of a StoreEntry.
    ///
    /// NOTE: The operations below should be a transaction, but this is not
    /// currently supported by this library.
    pub fn match_failed_transaction(
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
        firestore.write(
            &format!("users/{user_id}/failed"),
            Some(&format!(
                "{}_{}",
                &store_entry.storefront_name, &store_entry.id
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
        LibraryOps::write_game_entry(firestore, &game_entry)?;

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

/// Document type under 'users/{user_id}/storefronts/{storefront_name}'. They
/// are used as a quick way to check user's game ownership in a storefront.
///
/// NOTE: Used as a duplicate entry, instead of querying GameEntries and
/// StoreEntries, to reduce Firestore reads when syncing libraries.
#[derive(Serialize, Deserialize, Default, Debug)]
struct Storefront {
    name: String,

    #[serde(default)]
    #[serde(skip_serializing_if = "Vec::is_empty")]
    owned_games: Vec<String>,
}
