use crate::api::{EgsApi, FirestoreApi, GogApi, SteamApi};
use crate::documents::{GameEntry, StoreEntry};
use crate::library::library_ops::LibraryOps;
use crate::library::Reconciler;
use crate::traits;
use crate::Status;
use std::collections::HashSet;
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
    /// New entries are added as unreconciled / unmatched titles. Reconciliation
    /// with IGDB entries is a separate step that will be triggered
    /// independenlty.
    pub async fn sync_library(
        &self,
        steam_api: Option<SteamApi>,
        gog_api: Option<GogApi>,
        egs_api: Option<EgsApi>,
    ) -> Result<(), Status> {
        if let Some(api) = steam_api {
            self.sync_storefront(&api).await?;
        }
        if let Some(api) = gog_api {
            self.sync_storefront(&api).await?;
        }
        if let Some(api) = egs_api {
            self.sync_storefront(&api).await?;
        }

        Ok(())
    }

    /// Retieves new game entries from the provided remote storefront and
    /// modifies user's library in Firestore.
    ///
    /// This operation updates
    ///   (a) the `users/{user}/storefronts/{storefront_name}` document to
    ///   contain all storefront game ids owned by the user.
    ///   (b) the `users/{user}/unmatched` collection with 'StoreEntry` documents
    ///   that correspond to new found entries.
    async fn sync_storefront<T: traits::Storefront>(&self, api: &T) -> Result<(), Status> {
        let mut game_ids = HashSet::<String>::new();
        {
            game_ids.extend(
                LibraryOps::read_storefront_ids(
                    &self.firestore.lock().unwrap(),
                    &self.user_id,
                    &T::id(),
                )
                .into_iter(),
            );
        }
        let store_entries = api
            .get_owned_games()
            .await?
            .into_iter()
            .filter(|store_entry| !game_ids.contains(&store_entry.id))
            .collect::<Vec<StoreEntry>>();

        let firestore = &self.firestore.lock().unwrap();
        LibraryOps::write_unmatched_entries(firestore, &self.user_id, &T::id(), &store_entries)?;

        game_ids.extend(store_entries.into_iter().map(|store_entry| store_entry.id));
        LibraryOps::write_storefront_ids(
            firestore,
            &self.user_id,
            &T::id(),
            &game_ids.into_iter().collect::<Vec<_>>(),
        )?;

        Ok(())
    }

    /// Refreshes game entries info from IGDB in user's library.
    pub async fn refresh_entries(&self, recon_service: Reconciler) -> Result<(), Status> {
        let library_entries =
            LibraryOps::read_library_entries(&self.firestore.lock().unwrap(), &self.user_id)?;

        let (tx, mut rx) = mpsc::channel(32);

        tokio::spawn(async move {
            recon_service.refresh(tx, library_entries).await;
        });

        while let Some(refresh) = rx.recv().await {
            println!("  received refresh for {}", &refresh.library_entry.name);

            if let None = &refresh.game_entry {
                continue;
            }

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            tokio::spawn(async move {
                if let Err(status) = LibraryOps::update_library_entry(
                    &firestore.lock().unwrap(),
                    &user_id,
                    refresh.library_entry,
                    refresh.game_entry.unwrap(),
                ) {
                    eprintln!("Error handling library entry refresh: {}", status);
                }
            });
        }

        Ok(())
    }

    /// Reconciles entries in the unmatched collection of user's library.
    pub async fn match_entries(&self, recon_service: Reconciler) -> Result<(), Status> {
        let unmatched_entries =
            LibraryOps::read_unmatched_entries(&self.firestore.lock().unwrap(), &self.user_id)?;

        let (tx, mut rx) = mpsc::channel(32);

        tokio::spawn(async move {
            recon_service.reconcile(tx, unmatched_entries).await;
        });

        while let Some(entry_match) = rx.recv().await {
            println!("  received match for {}", &entry_match.store_entry.title);

            if let None = &entry_match.game_entry {
                continue;
            }

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            tokio::spawn(async move {
                if let Err(status) = LibraryOps::store_entry_match(
                    &firestore.lock().unwrap(),
                    &user_id,
                    entry_match.store_entry,
                    entry_match.game_entry.unwrap(),
                ) {
                    eprintln!("Error handling matching entry: {}", status);
                }
            });
        }

        Ok(())
    }

    /// Match a `StoreEntry` to a specified `GameEntry` and saving it in the
    /// user's library.
    ///
    /// Uses the `Reconciler` to retrieve full details for `GameEntry`.
    pub async fn manual_recon(
        &self,
        recon_service: Reconciler,
        store_entry: StoreEntry,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        // Retrieve full details GameEntry from recon service.
        let game_entry = self
            .retrieve_game_entry(game_entry.id, &recon_service)
            .await?;
        if let Some(parent_id) = game_entry.parent {
            let base_game_entry = self.retrieve_game_entry(parent_id, &recon_service).await?;
        }

        LibraryOps::store_entry_match(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            store_entry,
            game_entry,
        )
    }

    /// Returns a GameEntry based on `id`.
    ///
    /// If the GameEntry is not already available in Firestore it attemps to
    /// retrieve it from IGDB.
    async fn retrieve_game_entry(
        &self,
        id: u64,
        recon_service: &Reconciler,
    ) -> Result<GameEntry, Status> {
        let firestore = self.firestore.lock().unwrap();
        let game_entry = match LibraryOps::read_game_entry(&firestore, id) {
            Ok(entry) => entry,
            Err(_) => {
                drop(firestore);
                recon_service.retrieve(id).await?
            }
        };

        Ok(game_entry)
    }
}
