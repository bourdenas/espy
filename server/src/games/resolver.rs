use crate::{
    api::{FirestoreApi, IgdbApi},
    documents::GameEntry,
    library::firestore,
    util::rate_limiter::RateLimiter,
    Status,
};
use std::{
    sync::{Arc, Mutex},
    time::Duration,
};
use tokio::sync::mpsc;
use tracing::{error, instrument, trace_span, Instrument};

use super::SteamDataApi;

pub struct Resolver;

impl Resolver {
    /// Returns a GameEntry based on its IGDB `game_id`.
    ///
    /// It first tries to lookup the GameEntry in Firestore and only attemps to
    /// resolve it from IGDB if the lookup fails.
    #[instrument(level = "trace", skip(igdb, steam, firestore))]
    pub async fn retrieve(
        game_id: u64,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        firestore: Arc<Mutex<FirestoreApi>>,
    ) -> Result<Option<GameEntry>, Status> {
        match read_from_firestore(Arc::clone(&firestore), game_id) {
            // NOTE: There is a corner case that if a read is captured on a
            // GameEntry that is currently incrementally build (by another
            // request) the LibraryEntry that will be build from the returned
            // GameEntry can be incomplete. I just ignore the corner-case for
            // now.
            Ok(game_entry) => Ok(Some(game_entry)),
            Err(_) => Self::digest_resolve(game_id, igdb, steam, firestore).await,
        }
    }

    /// Fully resolve game info using IGDB and Steam using its IGDB `id`.
    ///
    /// This is a blocking call that can take several seconds due to QPS
    /// restrictions from IGDB API. There are asynchronous ways below like
    /// `schedule_resolve()` and `digest_resolve()`.
    #[instrument(level = "trace", skip(igdb, steam, firestore))]
    pub async fn resolve(
        game_id: u64,
        igdb: &IgdbApi,
        steam: &SteamDataApi,
        firestore: Arc<Mutex<FirestoreApi>>,
    ) -> Result<Option<GameEntry>, Status> {
        let (tx, mut rx) = mpsc::channel(32);

        match igdb.resolve(game_id, tx).await? {
            Some(mut game_entry) => {
                while let Some(fragment) = rx.recv().await {
                    game_entry.merge(fragment);
                }

                if let Err(e) = steam.retrieve_steam_data(&mut game_entry).await {
                    error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
                }

                firestore::games::write(&firestore.lock().unwrap(), &game_entry)?;
                Ok(Some(game_entry))
            }
            None => Ok(None),
        }
    }

    /// Schedules resolving of game info and returns a shallow copy of
    /// `GameEntry`.
    ///
    /// Returns immediately a shallow copy of `GameEntry` that consists of a
    /// single IGDB lookup. It spawns an async task to fully resolve the
    /// `GameEntry` and updates its Firestore entry. Updates to Firestore happen
    /// incrementally as new data is retrieved. Firestore updates are restricted
    /// to 1 per second, as the suggestion from the service.
    #[instrument(level = "trace", skip(igdb, steam, firestore))]
    pub async fn schedule_resolve(
        game_id: u64,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        firestore: Arc<Mutex<FirestoreApi>>,
    ) -> Result<Option<GameEntry>, Status> {
        let (tx, mut rx) = mpsc::channel(32);
        let shallow_game_entry = match igdb.resolve(game_id, tx).await? {
            Some(game) => game,
            None => return Ok(None),
        };

        let mut game_entry = shallow_game_entry.clone();
        tokio::spawn(
            async move {
                // Limit Firestore firestore writes on the same document to 1 qps.
                let rate_limiter = RateLimiter::new(1, Duration::from_secs(1), 1);
                if let Err(e) = update_firestore(firestore.clone(), &game_entry, &rate_limiter) {
                    error!("{e}");
                };

                while let Some(fragment) = rx.recv().await {
                    game_entry.merge(fragment);
                    if rate_limiter.try_wait() == Duration::from_micros(0) {
                        let firestore = &firestore.lock().unwrap();
                        if let Err(e) = firestore::games::write(firestore, &game_entry) {
                            error!("{e}");
                        }
                    }
                }

                if let Err(e) = steam.retrieve_steam_data(&mut game_entry).await {
                    error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
                }
                if let Err(e) = update_firestore(firestore.clone(), &game_entry, &rate_limiter) {
                    error!("{e}");
                };
            }
            .instrument(trace_span!("spawn_schedule_resolve")),
        );

        Ok(Some(shallow_game_entry))
    }

    /// Returns a `GameEntry` that has enough information to build a
    /// `GameDigest` doc.
    ///
    /// Returns immediately a `GameEntry` that is partially resolved containing
    /// enough data to build a `GameDigest. It spawns an async task to fully
    /// resolve the `GameEntry` and updates its Firestore entry.
    #[instrument(level = "trace", skip(igdb, steam, firestore))]
    pub async fn digest_resolve(
        game_id: u64,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        firestore: Arc<Mutex<FirestoreApi>>,
    ) -> Result<Option<GameEntry>, Status> {
        let game_entry_digest = match igdb.get_with_digest(game_id).await? {
            Some(game) => game,
            None => return Ok(None),
        };
        firestore::games::write(&firestore.lock().unwrap(), &game_entry_digest)?;

        tokio::spawn(
            async move {
                // TODO: This could be optimised as it resolves many fields that
                // are already resolved in the digest.
                Self::resolve(game_entry_digest.id, &igdb, &steam, firestore).await;
            }
            .instrument(trace_span!("spawn_schedule_resolve")),
        );

        Ok(Some(game_entry_digest))
    }
}

#[instrument(level = "trace", skip(firestore, rate_limiter))]
fn update_firestore(
    firestore: Arc<Mutex<FirestoreApi>>,
    game_entry: &GameEntry,
    rate_limiter: &RateLimiter,
) -> Result<(), Status> {
    rate_limiter.wait();
    firestore::games::write(&firestore.lock().unwrap(), &game_entry)?;
    Ok(())
}

/// NOTE: This function is needed to contain the lock scope.
fn read_from_firestore(firestore: Arc<Mutex<FirestoreApi>>, id: u64) -> Result<GameEntry, Status> {
    firestore::games::read(&firestore.lock().unwrap(), id)
}
