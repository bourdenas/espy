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
use tracing::{error, instrument};

use super::{Reconciler, SteamDataApi};

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
    ) -> Result<GameEntry, Status> {
        Ok(match read_from_firestore(Arc::clone(&firestore), game_id) {
            // NOTE: There is a corner case that if a read is captured on a
            // GameEntry that is currently incrementally build (by another
            // request) the LibraryEntry that will be build from the returned
            // GameEntry can be incomplete. I just ignore the corner-case for
            // now.
            Ok(game_entry) => game_entry,
            Err(_) => Self::resolve(game_id, igdb, steam, firestore).await?,
        })
    }

    #[instrument(level = "trace", skip(igdb, steam, firestore))]
    pub async fn resolve(
        game_id: u64,
        igdb: Arc<IgdbApi>,
        steam: Arc<SteamDataApi>,
        firestore: Arc<Mutex<FirestoreApi>>,
    ) -> Result<GameEntry, Status> {
        let recon_service = Reconciler::new(igdb, steam);

        let (tx, mut rx) = mpsc::channel(32);
        let mut game_entry = recon_service.resolve_incrementally(game_id, tx).await?;

        // Limit Firestore firestore writes to 1 qps.
        let rate_limiter = RateLimiter::new(1, Duration::from_secs(1), 1);

        Self::update_firestore(firestore.clone(), &game_entry, &rate_limiter)?;
        while let Some(fragment) = rx.recv().await {
            game_entry.merge(fragment);
            if rate_limiter.try_wait() == Duration::from_micros(0) {
                let firestore = &firestore.lock().unwrap();
                firestore::games::write(firestore, &game_entry)?;
            }
        }

        if let Err(e) = recon_service.update_steam_data(&mut game_entry).await {
            error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
        }
        Self::update_firestore(firestore, &game_entry, &rate_limiter)?;

        Ok(game_entry)
    }

    #[instrument(level = "trace", skip(firestore, rate_limiter))]
    fn update_firestore(
        firestore: Arc<Mutex<FirestoreApi>>,
        game_entry: &GameEntry,
        rate_limiter: &RateLimiter,
    ) -> Result<(), Status> {
        rate_limiter.wait();
        let firestore = &firestore.lock().unwrap();
        firestore::games::write(firestore, &game_entry)?;
        Ok(())
    }
}

/// NOTE: This function is needed to contain the lock scope.
fn read_from_firestore(firestore: Arc<Mutex<FirestoreApi>>, id: u64) -> Result<GameEntry, Status> {
    firestore::games::read(&firestore.lock().unwrap(), id)
}
