use crate::api::{FirestoreApi, GogApi, SteamApi};
use crate::documents::{LibraryEntry, StoreEntry};
use crate::library::Reconciler;
use crate::traits;
use crate::Status;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::iter::FromIterator;
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;

/// Proxy structure that handles operations regarding user's library.
pub struct LibraryManager {
    user_id: String,
    firestore: Arc<Mutex<FirestoreApi>>,
}

impl LibraryManager {
    /// Creates a LibraryManager instance for a user.
    pub fn new(user_id: &str, firestore: Arc<Mutex<FirestoreApi>>) -> Self {
        LibraryManager {
            user_id: String::from(user_id),
            firestore,
        }
    }

    /// Retrieves new entries from remote storefronts the user has access to and
    /// expands existing library entries.
    ///
    /// New entries are added as unreconciled / unknown titles. Reconciliation
    /// with IGDB entries is a separate step that will be triggered
    /// independenlty.
    pub async fn sync_library(
        &self,
        steam_api: Option<SteamApi>,
        gog_api: Option<GogApi>,
    ) -> Result<(), Status> {
        if let Some(api) = steam_api {
            self.sync_storefront("steam", &api).await?;
        }
        if let Some(api) = gog_api {
            self.sync_storefront("gog", &api).await?;
        }

        Ok(())
    }

    /// Retieves new game entries from the provided remote storefront and
    /// modifies user's library in Firestore.
    ///
    /// This operation updates
    ///   (a) the `users/{user}/storefronts/{storefront_name}` document to
    ///   contain all storefront game ids owned by the user.
    ///   (b) the `users/{user}/unknown` collection with [StoreEntry] documents
    ///   that correspond to new found entries.
    async fn sync_storefront<T: traits::Storefront>(
        &self,
        storefront_name: &str,
        api: &T,
    ) -> Result<(), Status> {
        let mut game_ids =
            HashSet::<i64>::from_iter(self.read_storefront_ids(storefront_name).into_iter());
        let store_entries = api
            .get_owned_games()
            .await?
            .into_iter()
            .filter(|store_entry| !game_ids.contains(&store_entry.id))
            .collect::<Vec<StoreEntry>>();

        self.write_unknown_entries(&store_entries)?;

        game_ids.extend(store_entries.iter().map(|store_entry| store_entry.id));
        self.write_storefront_ids(storefront_name, &game_ids.into_iter().collect::<Vec<i64>>())?;

        Ok(())
    }

    /// Reconciles unmatched entries in library.
    pub async fn reconcile(&self, recon_service: Reconciler) -> Result<(), Status> {
        let unknown_entries = self.read_unknown_entries()?;

        let (tx, mut rx) = mpsc::channel(32);

        tokio::spawn(async move {
            recon_service.reconcile(tx, unknown_entries).await;
        });

        while let Some(entry_match) = rx.recv().await {
            println!("  received match for {}", &entry_match.store_entry.title);

            if let None = &entry_match.game_entry {
                continue;
            }

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            tokio::spawn(async move {
                if let Err(status) = LibraryManager::store_match(firestore, &user_id, entry_match) {
                    eprintln!("Error handling recon match: {}", status);
                }
            });
        }

        Ok(())
    }

    /// Handles library Firestore updates on successful matching of game entry.
    fn store_match(
        firestore: Arc<Mutex<FirestoreApi>>,
        user_id: &str,
        m: crate::library::reconciler::Match,
    ) -> Result<(), Status> {
        if let None = &m.game_entry {
            return Ok(());
        }

        let game_entry = m.game_entry.unwrap();
        let firestore = firestore.lock().unwrap();

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
            store_entry: vec![m.store_entry],
            user_data: None,
        };

        // TODO: The three operations below should be a Transaction, but this is
        // not currently supported by this library.
        //
        // Delete matched StoreEntries from 'users/{user}/unknown'
        for store_entry in &library_entry.store_entry {
            firestore.delete(&format!(
                "users/{}/unknown/{}",
                user_id,
                store_entry.id.to_string()
            ))?;
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

    /// Returns all store game ids owned by user from specified storefront.
    ///
    /// Reads `users/{user}/storefront/{storefront_name}` document in Firestore.
    fn read_storefront_ids(&self, name: &str) -> Vec<i64> {
        match self
            .firestore
            .lock()
            .unwrap()
            .read::<Storefront>(&format!("users/{}/storefronts", self.user_id), name)
        {
            Ok(storefront) => storefront.owned_games,
            Err(_) => vec![],
        }
    }

    /// Writes all store game ids owned by user from specified storefront.
    ///
    /// Writes `users/{user}/storefront/{storefront_name}` document in
    /// Firestore.
    fn write_storefront_ids(&self, name: &str, ids: &[i64]) -> Result<(), Status> {
        match self.firestore.lock().unwrap().write(
            &format!("users/{}/storefronts", self.user_id),
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

    /// Create new library entries for newly found storefront entries.
    ///
    /// Writes [StoreEntry] documents under collection `users/{user}/unknown` in
    /// Firestore.
    fn write_unknown_entries(&self, entries: &[StoreEntry]) -> Result<(), Status> {
        for entry in entries {
            self.firestore.lock().unwrap().write(
                &format!("users/{}/unknown", self.user_id),
                Some(&entry.id.to_string()),
                entry,
            )?;
        }
        Ok(())
    }

    fn read_unknown_entries(&self) -> Result<Vec<StoreEntry>, Status> {
        match self
            .firestore
            .lock()
            .unwrap()
            .list::<StoreEntry>(&format!("users/{}/unknown", self.user_id))
        {
            Ok(entries) => Ok(entries),
            Err(e) => Err(Status::internal("LibraryManager.read_unknown_entries: ", e)),
        }
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
    owned_games: Vec<i64>,
}
