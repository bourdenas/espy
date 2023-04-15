use crate::{
    api::{FirestoreApi, IgdbApi},
    documents::GameEntry,
    library::firestore,
    Status,
};
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;
use tracing::{error, instrument, trace_span, Instrument};

use super::SteamDataApi;

pub struct Resolver;

impl Resolver {
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
            Some(_shallow_game_entry) => {
                let mut requested_game_entry = None;
                while let Some(mut game_entry) = rx.recv().await {
                    if let Err(e) = steam.retrieve_steam_data(&mut game_entry).await {
                        error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
                    }

                    firestore::games::write(&firestore.lock().unwrap(), &game_entry)?;
                    requested_game_entry = Some(game_entry);
                }

                // This is based on knowing that the last game_entry returned is
                // the one requested by game_id.
                Ok(requested_game_entry)
            }
            None => Ok(None),
        }
    }

    /// Schedules resolving of game info and returns a shallow copy of
    /// `GameEntry`.
    ///
    /// Returns immediately a shallow copy of `GameEntry` that consists of two
    /// IGDB lookup. It spawns an async task to fully resolve the `GameEntry`
    /// and updates its Firestore entry.
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

        let game_entry = shallow_game_entry.clone();
        tokio::spawn(
            async move {
                if let Err(e) = firestore::games::write(&firestore.lock().unwrap(), &game_entry) {
                    error!("{e}");
                };

                while let Some(mut game_entry) = rx.recv().await {
                    if let Err(e) = steam.retrieve_steam_data(&mut game_entry).await {
                        error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
                    }

                    if let Err(e) = firestore::games::write(&firestore.lock().unwrap(), &game_entry)
                    {
                        error!("{e}");
                    }
                }
            }
            .instrument(trace_span!("spawn_schedule_resolve")),
        );

        Ok(Some(shallow_game_entry))
    }
}
