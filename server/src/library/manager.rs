use crate::api::{FirestoreApi, GogApi, SteamApi};
use crate::espy;
use crate::library::Reconciler;
use crate::models::StoreEntry;
use crate::traits;
use crate::util;
use crate::Status;
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::iter::FromIterator;
use std::mem::swap;
use std::sync::{Arc, Mutex};

/// Proxy structure that handles operations regarding user's library.
pub struct LibraryManager {
    pub library: espy::Library,
    path: String,
    user_id: String,
    firestore: Arc<Mutex<FirestoreApi>>,
}

impl LibraryManager {
    /// Creates a LibraryManager instance for a user.
    pub fn new(user_id: &str, firestore: Arc<Mutex<FirestoreApi>>) -> Self {
        LibraryManager {
            library: espy::Library::default(),
            path: format!("users/{}/library", user_id),
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
    /// Writes [Storefront] documents under collection `users/{user}/unknown` in
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

    /// Reconciles unmatched entries in library.
    pub async fn reconcile(&mut self, recon_service: Reconciler) -> Result<(), Status> {
        self.update_library(
            recon_service
                .reconcile(&self.library.unreconciled_store_entry)
                .await?,
        );

        // Save changes in local library.
        util::proto::save(&self.path, &self.library)?;

        Ok(())
    }

    // Merges update into existing library. Ensures that there are no duplicate
    // entries.
    fn update_library(&mut self, update: espy::Library) {
        self.library.unreconciled_store_entry = update.unreconciled_store_entry;
        if update.entry.is_empty() {
            return;
        }

        let mut entries = vec![];
        swap(&mut entries, &mut self.library.entry);
        entries.extend(update.entry);

        // Sort entries by Game.id and aggregate in groups entries with the same
        // Game.id.
        entries.sort_by_key(|e| match &e.game {
            Some(game) => game.id,
            None => 0,
        });
        let groups = entries.into_iter().group_by(|e| match &e.game {
            Some(game) => game.id,
            None => 0,
        });

        // Collapse groups of same Game into a single entry and maintain
        // ownership in different stores.
        for (_key, mut group) in groups.into_iter() {
            let init = group.next().unwrap_or_default();
            let group = group.collect::<Vec<espy::GameEntry>>();
            self.library.entry.push(match group.is_empty() {
                false => group.into_iter().fold(init, |acc, x| {
                    let mut entry = acc;
                    entry.store_entry.extend(x.store_entry);
                    entry
                }),
                true => init,
            });
        }
    }
}

#[derive(Serialize, Deserialize, Default, Debug)]
struct GameEntry {
    uid: String,
    name: String,
    cover: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    user_data: Option<GameUserData>,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    store_entry: Vec<StoreEntry>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
struct GameUserData {
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tags: Vec<String>,
}

/// Document type under /users/{user_id}/storefronts/{storefront_name}. They are
/// used as a quick way to check user's game ownership in a storefront.
///
/// NOTE: Used as a duplicate entry, instead of querying GameEntries and
/// StoreEntries, to reduce Firestore reads when syncing libraries.
#[derive(Serialize, Deserialize, Default, Debug)]
struct Storefront {
    name: String,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    owned_games: Vec<i64>,
}
