use crate::{
    api::{FirestoreApi, GogApi, IgdbApi, SteamApi},
    documents::{GameEntry, LibraryEntry, StoreEntry},
    library::{
        library_ops::LibraryOps, library_transactions::LibraryTransactions,
        library_transactions::Op, reconciler::Match, steam_data::SteamDataApi, ReconReport,
        Reconciler,
    },
    traits,
    util::rate_limiter::RateLimiter,
    Status,
};
use std::{
    sync::{Arc, Mutex},
    time::Duration,
};
use tokio::sync::mpsc;
use tracing::{error, info, instrument, trace_span, Instrument};

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
    #[instrument(
        level = "trace",
        skip(self, steam_api, gog_api, igdb, steam),
        fields(user_id = %self.user_id),
    )]
    pub async fn sync_library(
        &self,
        steam_api: Option<SteamApi>,
        gog_api: Option<GogApi>,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<ReconReport, Status> {
        if let Some(api) = steam_api {
            self.sync_storefront(&api).await?;
        }
        if let Some(api) = gog_api {
            self.sync_storefront(&api).await?;
        }

        let unmatched_entries =
            LibraryOps::list_unmatched(&self.firestore.lock().unwrap(), &self.user_id)?;
        self.recon_store_entries(unmatched_entries, igdb, steam)
            .await
    }

    /// Reconciles `store_entries` and adds them in the user's library.
    #[instrument(
        level = "trace",
        skip(self, store_entries, igdb, steam),
        fields(
            user_id = %self.user_id,
            entries_num = %store_entries.len()
        ),
    )]
    pub async fn recon_store_entries(
        &self,
        store_entries: Vec<StoreEntry>,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<ReconReport, Status> {
        let (tx, rx) = mpsc::channel(32);

        tokio::spawn(
            async move {
                Reconciler::new(igdb, steam)
                    .reconcile(tx, store_entries)
                    .await;
            }
            .instrument(trace_span!("spawn recon job")),
        );

        Ok(self.receive_matches(rx).await)
    }

    /// Match a `StoreEntry` to a specified `GameEntry` and saving it in the
    /// user's library.
    #[instrument(level = "trace", skip(self, igdb, steam))]
    pub async fn manual_match(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<(), Status> {
        let recon_service = Reconciler::new(igdb, steam);

        let owned_game_id = game_entry.id;
        let game_id = match game_entry.parent {
            Some(parent_id) => parent_id,
            None => game_entry.id,
        };

        let game_entry = self.retrieve_game_entry(game_id, &recon_service).await?;
        LibraryTransactions::match_game(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            store_entry,
            owned_game_id,
            game_entry,
        )
    }

    /// Unmatch a `StoreEntry` from user's library. The StoreEntry is not
    /// deleted. Instead it is moved into the failed matches.
    #[instrument(level = "trace", skip(self, library_entry))]
    pub async fn unmatch_game(
        &self,
        store_entry: &StoreEntry,
        library_entry: LibraryEntry,
    ) -> Result<(), Status> {
        LibraryTransactions::unmatch_game(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            store_entry,
            library_entry,
            Op::Failed,
        )
    }

    /// Deletes a `StoreEntry` from user's library. The StoreEntry is completely
    /// removed.
    #[instrument(level = "trace", skip(self, library_entry))]
    pub async fn delete_game(
        &self,
        store_entry: &StoreEntry,
        library_entry: LibraryEntry,
    ) -> Result<(), Status> {
        LibraryTransactions::unmatch_game(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            store_entry,
            library_entry,
            Op::Delete,
        )
    }

    #[instrument(level = "trace", skip(self, igdb, steam))]
    pub async fn rematch_game(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        existing_library_entry: LibraryEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<(), Status> {
        LibraryTransactions::unmatch_game(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            &store_entry,
            existing_library_entry,
            Op::Unmatch,
        )?;

        self.exact_manual_match(store_entry, game_entry, igdb, steam)
            .await
    }

    /// Match a `StoreEntry` to a specified `GameEntry` and saving it in the
    /// user's library. It matches with an explicit GameEntry instead of trying
    /// to match it with its parent.
    #[instrument(level = "trace", skip(self, igdb, steam))]
    async fn exact_manual_match(
        &self,
        store_entry: StoreEntry,
        game_entry: GameEntry,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
    ) -> Result<(), Status> {
        let recon_service = Reconciler::new(igdb, steam);

        let game_entry = self
            .retrieve_game_entry(game_entry.id, &recon_service)
            .await?;
        LibraryTransactions::match_game(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            store_entry,
            game_entry.id,
            game_entry,
        )
    }

    async fn receive_matches(&self, mut rx: mpsc::Receiver<Match>) -> ReconReport {
        let mut report = ReconReport { lines: vec![] };

        while let Some(entry_match) = rx.recv().await {
            match &entry_match.game_entry {
                Some(entry) => report.lines.push(format!(
                    "matched '{}' ({}) with {}",
                    &entry_match.store_entry.title,
                    &entry_match.store_entry.storefront_name,
                    &entry.name,
                )),
                None => report.lines.push(format!(
                    "failed to match {} ({})",
                    &entry_match.store_entry.title, &entry_match.store_entry.storefront_name,
                )),
            };

            let firestore = Arc::clone(&self.firestore);
            let user_id = self.user_id.clone();
            tokio::spawn(
                async move {
                    let firestore = &firestore.lock().unwrap();
                    match entry_match.game_entry {
                        Some(game_entry) => {
                            LibraryOps::write_game_entry(firestore, &game_entry)
                                .expect("Firestore write_game_entry()");
                            LibraryTransactions::match_game(
                                firestore,
                                &user_id,
                                entry_match.store_entry,
                                game_entry.id,
                                game_entry,
                            )
                            .expect("Firestore match_game_transaction()")
                        }
                        None => LibraryTransactions::match_failed(
                            firestore,
                            &user_id,
                            &entry_match.store_entry,
                        )
                        .expect("Firestore match_failed_transaction()"),
                    }
                }
                .instrument(trace_span!("spawn handle match")),
            );
        }
        report
    }

    /// Returns a GameEntry based on its IGDB `id`.
    ///
    /// It first tries to lookup the GameEntry in Firestore and only attemps to
    /// resolve it from IGDB if the lookup fails.
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
            // NOTE: There is a corner case that if a read is captured on a
            // GameEntry that is currently incrementally build (by another
            // request) the LibraryEntry that will be build from the returned
            // GameEntry can be incomplete. I just ignore the corner-case for
            // now.
            Ok(game_entry) => game_entry,
            Err(_) => {
                let (tx, mut rx) = mpsc::channel(32);
                let mut game_entry = recon_service.resolve_incrementally(id, tx).await?;

                // Limit Firestore fragment updates to 1 every 2 sec.
                let rate_limiter = RateLimiter::new(1, Duration::from_secs(2), 1);
                while let Some(fragment) = rx.recv().await {
                    game_entry.merge(fragment);
                    if rate_limiter.try_wait() == Duration::from_micros(0) {
                        info!("uploading fragments to Firestore");
                        let firestore = &self.firestore.lock().unwrap();
                        LibraryOps::write_game_entry(firestore, &game_entry)?;
                    }
                }

                if let Err(e) = recon_service.update_steam_data(&mut game_entry).await {
                    error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
                }
                info!("final game entry update to Firestore");
                let firestore = &self.firestore.lock().unwrap();
                LibraryOps::write_game_entry(firestore, &game_entry)?;

                game_entry
            }
        };

        Ok(game_entry)
    }

    /// NOTE: This function is needed to contain the lock scope.
    #[instrument(level = "trace", skip(self))]
    fn read_from_firestore(&self, id: u64) -> Result<GameEntry, Status> {
        LibraryOps::read_game_entry(&self.firestore.lock().unwrap(), id)
    }

    /// Retieves new game entries from the provided remote storefront and
    /// temporarily stores them in unmatched in Firestore.
    #[instrument(level = "trace", skip(self, api))]
    async fn sync_storefront<T: traits::Storefront>(&self, api: &T) -> Result<(), Status> {
        let store_entries = api.get_owned_games().await?;
        LibraryTransactions::store_new_to_unmatched(
            &self.firestore.lock().unwrap(),
            &self.user_id,
            &T::id(),
            store_entries,
        )
    }
}
