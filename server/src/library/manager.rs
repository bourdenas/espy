use super::reconciler::Match;
use crate::{
    api::{FirestoreApi, GogApi, SteamApi},
    documents::{GameEntry, StoreEntry},
    library::library_ops::LibraryOps,
    library::Reconciler,
    traits, Status,
};
use std::{
    collections::HashSet,
    sync::{Arc, Mutex},
};
use tokio::sync::mpsc;
use tracing::{info, instrument, trace_span, Instrument};

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
    #[instrument(
        level = "trace",
        skip(self, steam_api, gog_api, recon_service),
        fields(user_id = %self.user_id),
    )]
    pub async fn sync_library(
        &self,
        steam_api: Option<SteamApi>,
        gog_api: Option<GogApi>,
        recon_service: Reconciler,
    ) -> Result<(), Status> {
        if let Some(api) = steam_api {
            self.sync_storefront(&api).await?;
        }
        if let Some(api) = gog_api {
            self.sync_storefront(&api).await?;
        }

        self.recon_unmatched_entries(recon_service).await?;

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
    #[instrument(
        level = "trace",
        skip(self, api),
        fields(user_id = %self.user_id),
    )]
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
    #[instrument(
        level = "trace",
        skip(self, recon_service),
        fields(user_id = %self.user_id),
    )]
    pub async fn refresh_entries(&self, recon_service: Reconciler) -> Result<(), Status> {
        let library_entries =
            LibraryOps::read_library_entries(&self.firestore.lock().unwrap(), &self.user_id)?;
        let library_entries = library_entries.into_iter().take(5).collect();

        let (tx, mut rx) = mpsc::channel(32);

        let _handle = tokio::spawn(
            async move {
                recon_service.refresh(tx, library_entries).await;
            }
            .instrument(trace_span!("spawn refresh task")),
        );

        while let Some(refresh) = rx.recv().await {
            info!("refreshed '{}'", &refresh.library_entry.name);

            if let None = &refresh.game_entry {
                continue;
            }

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            let _handle = tokio::spawn(
                async move {
                    LibraryOps::update_library_entry(
                        &firestore.lock().unwrap(),
                        &user_id,
                        refresh.library_entry,
                        refresh.game_entry.unwrap(),
                    )
                    .expect("Firestore update_library_entry():")
                }
                .instrument(trace_span!("spawn Firestore update task")),
            );
        }

        Ok(())
    }

    /// Reconciles entries in the unmatched collection of user's library.
    #[instrument(
        level = "trace",
        skip(self, recon_service),
        fields(user_id = %self.user_id),
    )]
    async fn recon_unmatched_entries(&self, recon_service: Reconciler) -> Result<(), Status> {
        let unmatched_entries =
            LibraryOps::read_unmatched_entries(&self.firestore.lock().unwrap(), &self.user_id)?;

        self.recon_store_entries(unmatched_entries, recon_service)
            .await?;
        Ok(())
    }

    /// Reconciles entries in the unmatched collection of user's library.
    #[instrument(
        level = "trace",
        skip(self, store_entries, recon_service),
        fields(
            user_id = %self.user_id,
            entries_num = %store_entries.len()
        ),
    )]
    pub async fn recon_store_entries(
        &self,
        store_entries: Vec<StoreEntry>,
        recon_service: Reconciler,
    ) -> Result<(), Status> {
        let (tx, rx) = mpsc::channel(32);

        tokio::spawn(
            async move {
                recon_service.reconcile(tx, store_entries).await;
            }
            .instrument(trace_span!("spawn recon job")),
        );

        self.handle_matches(rx).await;
        Ok(())
    }

    async fn handle_matches(&self, mut rx: mpsc::Receiver<Match>) {
        while let Some(entry_match) = rx.recv().await {
            match &entry_match.game_entry {
                Some(_) => info!("  👍 received match for {}", &entry_match.store_entry.title),
                None => info!("  🚫 no match for {}", &entry_match.store_entry.title),
            };

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            tokio::spawn(
                async move {
                    let firestore = &firestore.lock().unwrap();
                    match entry_match.game_entry {
                        Some(game_entry) => LibraryOps::game_match_transaction(
                            firestore,
                            &user_id,
                            entry_match.store_entry,
                            game_entry.id,
                            game_entry,
                        )
                        .expect("Firestore game_match_transaction()"),
                        None => LibraryOps::match_failed_transaction(
                            firestore,
                            &user_id,
                            entry_match.store_entry,
                        )
                        .expect("Firestore match_failed_transaction()"),
                    }
                }
                .instrument(trace_span!("spawn handle match")),
            );
        }
    }

    /// Match a `StoreEntry` to a specified `GameEntry` and saving it in the
    /// user's library.
    ///
    /// Uses the `Reconciler` to retrieve full details for `GameEntry`.
    #[instrument(
        level = "trace",
        skip(self, recon_service),
        fields(user_id = %self.user_id),
    )]
    pub async fn manual_match(
        &self,
        recon_service: Reconciler,
        store_entry: StoreEntry,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        // Retrieve full details GameEntry from recon service.
        let mut game_entry = self
            .retrieve_game_entry(game_entry.id, &recon_service)
            .await?;
        let owned_game_id = game_entry.id;
        if let Some(parent_id) = game_entry.parent {
            game_entry = self.retrieve_game_entry(parent_id, &recon_service).await?;
        }

        LibraryOps::game_match_transaction(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            store_entry,
            owned_game_id,
            game_entry,
        )
    }

    /// Returns a GameEntry based on `id`.
    ///
    /// If the GameEntry is not already available in Firestore it attemps to
    /// retrieve it from IGDB.
    #[instrument(
        level = "trace",
        skip(self, recon_service),
        fields(user_id = %self.user_id),
    )]
    async fn retrieve_game_entry(
        &self,
        id: u64,
        recon_service: &Reconciler,
    ) -> Result<GameEntry, Status> {
        let game_entry = match self.read_from_firestore(id) {
            Ok(entry) => entry,
            Err(_) => {
                let game_entry = recon_service.retrieve(id).await?;
                game_entry
            }
        };

        Ok(game_entry)
    }

    #[instrument(level = "trace", skip(self))]
    fn read_from_firestore(&self, id: u64) -> Result<GameEntry, Status> {
        LibraryOps::read_game_entry(&self.firestore.lock().unwrap(), id)
    }
}
