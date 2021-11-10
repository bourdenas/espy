use crate::api::FirestoreApi;
use crate::documents::{GameEntry, LibraryEntry, StoreEntry};
use crate::Status;
use serde::{Deserialize, Serialize};

pub struct LibraryOps {}

impl LibraryOps {
    /// Store storefront entries to user's library under unknown entries.
    ///
    /// Writes `StoreEntry` documents under collection `users/{user}/unknown` in
    /// Firestore.
    pub fn write_unknown_entries(
        firestore: &FirestoreApi,
        user_id: &str,
        entries: &[StoreEntry],
    ) -> Result<(), Status> {
        for entry in entries {
            firestore.write(
                &format!("users/{}/unknown", user_id),
                Some(&entry.id),
                entry,
            )?;
        }
        Ok(())
    }

    /// Read unknown storefront entries in user's library.
    ///
    /// Reads `StoreEntry` documents under collection `users/{user}/unknown` in
    /// Firestore.
    pub fn read_unknown_entries(
        firestore: &FirestoreApi,
        user_id: &str,
    ) -> Result<Vec<StoreEntry>, Status> {
        match firestore.list::<StoreEntry>(&format!("users/{}/unknown", user_id)) {
            Ok(entries) => Ok(entries),
            Err(e) => Err(Status::internal("LibraryManager.read_unknown_entries: ", e)),
        }
    }

    /// Returns user's matched game library entries.
    ///
    /// Reads `LibraryEntry` documents under collection `users/{user}/library` in
    /// Firestore.
    pub fn read_library_entries(
        firestore: &FirestoreApi,
        user_id: &str,
    ) -> Result<Vec<LibraryEntry>, Status> {
        match firestore.list::<LibraryEntry>(&format!("users/{}/library", user_id)) {
            Ok(entries) => Ok(entries),
            Err(e) => Err(Status::internal("LibraryManager.read_library_entries: ", e)),
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
            Err(e) => Err(Status::internal("LibraryManager.write_storefront_ids: ", e)),
        }
    }

    /// Returns all store game ids owned by user from specified storefront.
    ///
    /// Reads `users/{user}/storefront/{storefront_name}` document in Firestore.
    pub fn read_storefront_ids(firestore: &FirestoreApi, user_id: &str, name: &str) -> Vec<String> {
        match firestore.read::<Storefront>(&format!("users/{}/storefronts", user_id), name) {
            Ok(storefront) => storefront.owned_games,
            Err(_) => vec![],
        }
    }

    /// Handles library Firestore updates on successful matching input
    /// StoreEntry with GameEntry.
    pub fn store_entry_match(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        // Store GameEntry to 'games' collection. Might overwrite an existing
        // one. That's ok as this is a fresher version.
        firestore.write("games", Some(&game_entry.id.to_string()), &game_entry)?;

        // Create LibraryEntry from IgdbEntry and StoreEntry.
        let mut library_entry = LibraryEntry {
            id: game_entry.id,
            name: game_entry.name,
            cover: match game_entry.cover {
                Some(cover) => Some(cover.image_id),
                None => None,
            },
            release_date: game_entry.release_date,
            collection: game_entry.collection,
            franchises: game_entry.franchises,
            companies: game_entry.companies,
            store_entry: vec![store_entry],
            user_data: None,
        };

        // TODO: The three operations below should be a transaction, but this is
        // not currently supported by this library.
        //
        // Delete matched StoreEntries from 'users/{user}/unknown'
        for store_entry in &library_entry.store_entry {
            firestore.delete(&format!("users/{}/unknown/{}", user_id, store_entry.id))?;
        }

        // Check if game is already in user's library.
        if let Ok(existing) = firestore.read::<LibraryEntry>(
            &format!("users/{}/library", user_id),
            &library_entry.id.to_string(),
        ) {
            // Use the most recently retrieved entry from IGDB to include any
            // updates and merge existing user data for the entry (e.g. tags)
            // and other store entries.
            library_entry
                .store_entry
                .extend(existing.store_entry.into_iter());
            library_entry.user_data = existing.user_data;
        }

        // Store GameEntries to 'users/{user}/library' collection.
        firestore.write(
            &format!("users/{}/library", user_id),
            Some(&library_entry.id.to_string()),
            &library_entry,
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
        firestore.write("games", Some(&game_entry.id.to_string()), &game_entry)?;

        // Store GameEntries to 'users/{user}/library' collection.
        firestore.write(
            &format!("users/{}/library", user_id),
            Some(&library_entry.id.to_string()),
            &LibraryEntry {
                id: game_entry.id,
                name: game_entry.name,
                cover: match game_entry.cover {
                    Some(cover) => Some(cover.image_id),
                    None => None,
                },
                release_date: game_entry.release_date,
                collection: game_entry.collection,
                franchises: game_entry.franchises,
                companies: game_entry.companies,
                store_entry: library_entry.store_entry,
                user_data: library_entry.user_data,
            },
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
