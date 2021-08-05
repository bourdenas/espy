use crate::api::{FirestoreApi, GogApi, SteamApi};
use crate::documents::{GameEntry, LibraryEntry, StoreEntry};
use crate::library::Reconciler;
use crate::traits;
use crate::Status;
use itertools::Itertools;
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

        let mut matches = vec![];
        while let Some(entry_match) = rx.recv().await {
            println!("  received match for {}", &entry_match.store_entry.title);
            matches.push(entry_match);
        }

        // Store igdb entries to /games collection.
        self.write_games(
            &matches
                .iter()
                .filter_map(|m| match &m.game_entry {
                    Some(e) => Some(e),
                    None => None,
                })
                .collect::<Vec<&GameEntry>>(),
        )?;

        // Create LibraryEntry from IgdbEntry and StoreEntry.
        let mut game_entries = matches
            .into_iter()
            .filter_map(|m| match m.game_entry {
                Some(game_entry) => Some(LibraryEntry {
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
                }),
                None => None,
            })
            .collect::<Vec<LibraryEntry>>();

        // Group entries by id. User may have same game in multiple storefronts.
        game_entries.sort_by_key(|e| e.id);
        let groups = game_entries.into_iter().group_by(|e| e.id);

        // Collapse groups into a single entry and maintain ownership in
        // different stores.
        let game_entries = groups
            .into_iter()
            .map(|(_key, mut group)| {
                let init = group.next().unwrap_or_default();
                group.fold(init, |mut acc, x| {
                    acc.store_entry.extend(x.store_entry);
                    acc
                })
            })
            .collect::<Vec<LibraryEntry>>();

        // Store GameEntries to 'users/{user}/library' collection.
        self.write_game_entries(&game_entries)?;

        // Delete matched StoreEntries from 'users/{user}/unknown'
        self.delete_unknown_entries(&game_entries)?;

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

    fn write_games(&self, entries: &[&GameEntry]) -> Result<(), Status> {
        for entry in entries {
            self.firestore.lock().unwrap().write::<GameEntry>(
                "games",
                Some(&entry.id.to_string()),
                entry,
            )?;
        }
        Ok(())
    }

    fn write_game_entries(&self, entries: &[LibraryEntry]) -> Result<(), Status> {
        for entry in entries {
            self.firestore.lock().unwrap().write::<LibraryEntry>(
                &format!("users/{}/library", self.user_id),
                Some(&entry.id.to_string()),
                &entry,
            )?;
        }
        Ok(())
    }

    fn delete_unknown_entries(&self, entries: &[LibraryEntry]) -> Result<(), Status> {
        for entry in entries {
            for store_entry in &entry.store_entry {
                self.firestore.lock().unwrap().delete(&format!(
                    "users/{}/unknown/{}",
                    self.user_id,
                    store_entry.id.to_string()
                ))?;
            }
        }
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

    #[serde(skip_serializing_if = "Vec::is_empty")]
    owned_games: Vec<i64>,
}
