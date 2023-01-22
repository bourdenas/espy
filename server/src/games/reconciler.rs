use crate::{
    api::IgdbApi,
    documents::{GameEntry, StoreEntry},
    Status,
};
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;
use tracing::{debug, error, instrument, trace_span, Instrument};

use super::SteamDataApi;

pub struct Reconciler {
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
}

// The result of a reconcile operation on a `store_entry` with a `game_entry`
// from IGDB.
#[derive(Default)]
pub struct ReconMatch {
    pub store_entry: StoreEntry,
    pub game_entry: Option<GameEntry>,
}

impl Reconciler {
    pub fn new(igdb: Arc<IgdbApi>, steam: Arc<SteamDataApi>) -> Reconciler {
        Reconciler { igdb, steam }
    }

    /// Returns a shallow GameEntry based on its IGDB `id`.
    #[instrument(level = "trace", skip(self))]
    pub async fn get(&self, id: u64) -> Result<GameEntry, Status> {
        match self.igdb.get(id).await? {
            Some(game) => Ok(game),
            None => Err(Status::not_found(format!(
                "Failed to retrieve IGDB game with id={id}."
            ))),
        }
    }

    /// Returns a fully resolved GameEntry based on its IGDB `id` that also
    /// includes Steam data.
    #[instrument(level = "trace", skip(self))]
    pub async fn resolve(&self, id: u64) -> Result<GameEntry, Status> {
        resolve_game(id, &self.igdb, &self.steam).await
    }

    /// Returns a resolved GameEntry based on its IGDB `id` incrementally.
    ///
    /// It returns directly a shallow GameEntry and then using the mpsc::Sender
    /// provided it sends fragments of the remaining GameEntry until it is
    /// resolved, but excludes Steam data.
    #[instrument(level = "trace", skip(self))]
    pub async fn resolve_incrementally(
        &self,
        id: u64,
        tx: mpsc::Sender<GameEntry>,
    ) -> Result<GameEntry, Status> {
        match self.igdb.resolve(id, tx).await? {
            Some(game) => Ok(game),
            None => Err(Status::not_found(format!(
                "Failed to retrieve IGDB game with id={id}."
            ))),
        }
    }

    /// Updated Steam data for GameEntry and all its sub-entries.
    pub async fn update_steam_data(&self, game: &mut GameEntry) -> Result<(), Status> {
        self.steam.retrieve_steam_data(game).await
    }

    /// Matches input `store_entries` with IGDB GameEntries.
    ///
    /// Uses Sender endpoint to emit `ReconMatch`es. A `ReconMatch` is emitted both on
    /// successful or failed matches.
    #[instrument(
        level = "trace",
        skip(self, tx, store_entries),
        fields(entries_len = %store_entries.len()),
    )]
    pub async fn reconcile(&self, tx: mpsc::Sender<ReconMatch>, store_entries: Vec<StoreEntry>) {
        let fut = stream::iter(store_entries.into_iter().map(|store_entry| MatchingTask {
            store_entry,
            igdb: Arc::clone(&self.igdb),
            steam: Arc::clone(&self.steam),
            tx: tx.clone(),
        }))
        .for_each_concurrent(4, match_task)
        .instrument(trace_span!("spawn match tasks"));

        fut.await;
        drop(tx);
    }
}

impl ReconMatch {
    async fn success(
        store_entry: StoreEntry,
        game_entry: GameEntry,
        igdb: &IgdbApi,
        steam: &SteamDataApi,
    ) -> Self {
        let resolved = resolve_game(
            match game_entry.parent {
                Some(parent_id) => parent_id,
                None => game_entry.id,
            },
            igdb,
            steam,
        )
        .await;

        ReconMatch {
            store_entry,
            game_entry: match resolved {
                Ok(game_entry) => Some(game_entry),
                Err(e) => {
                    error!(
                        "Failed to retrieve game '{}' ({}) or its base game ({:?})\nerror: {e}",
                        &game_entry.name, game_entry.id, game_entry.parent,
                    );
                    None
                }
            },
        }
    }

    fn fail(store_entry: StoreEntry) -> Self {
        ReconMatch {
            store_entry,
            ..Default::default()
        }
    }
}

async fn resolve_game(
    game_id: u64,
    igdb: &IgdbApi,
    steam: &SteamDataApi,
) -> Result<GameEntry, Status> {
    let (tx, mut rx) = mpsc::channel(32);

    match igdb.resolve(game_id, tx).await? {
        Some(mut game) => {
            while let Some(fragment) = rx.recv().await {
                game.merge(fragment);
            }

            if let Err(e) = steam.retrieve_steam_data(&mut game).await {
                error!("Failed to retrieve SteamData for '{}' {e}", game.name);
            }
            Ok(game)
        }
        None => Err(Status::not_found(format!(
            "Failed to retrieve IGDB game with id={game_id}."
        ))),
    }
}

#[instrument(
    level = "trace",
    skip(task),
    fields(store_entry = %task.store_entry),
)]
async fn match_task(task: MatchingTask) {
    let entry_match = match match_by_external_id(&task.igdb, &task.store_entry).await {
        Ok(game_entry) => match game_entry {
            Some(game_entry) => {
                ReconMatch::success(task.store_entry, game_entry, &task.igdb, &task.steam).await
            }
            None => match match_by_title(&task.igdb, &task.store_entry.title).await {
                Ok(game_entry) => match game_entry {
                    Some(game_entry) => {
                        ReconMatch::success(task.store_entry, game_entry, &task.igdb, &task.steam)
                            .await
                    }
                    None => ReconMatch::fail(task.store_entry),
                },
                Err(e) => {
                    error!("match_by_title '{}' failed: {e}", task.store_entry.title);
                    ReconMatch::fail(task.store_entry)
                }
            },
        },
        Err(e) => {
            error!(
                "match_by_external_id '{}' failed: {e}",
                task.store_entry.title
            );
            ReconMatch::fail(task.store_entry)
        }
    };

    if let Err(e) = task.tx.send(entry_match).await {
        error!("{e}");
    }
}

/// Returns a `GameEntry` from IGDB matching the external storefront id in
/// `store_entry`.
async fn match_by_external_id(
    igdb: &IgdbApi,
    store_entry: &StoreEntry,
) -> Result<Option<GameEntry>, Status> {
    debug!("Resolving '{}'", &store_entry.title);

    match store_entry.id.is_empty() {
        true => Ok(None),
        false => igdb.get_by_store_entry(store_entry).await,
    }
}

/// Returns a `GameEntry` from IGDB matching the `title`.
async fn match_by_title(igdb: &IgdbApi, title: &str) -> Result<Option<GameEntry>, Status> {
    debug!("Searching '{}'", title);

    let candidates = igdb.get_by_title(title).await?;
    match candidates.into_iter().next() {
        Some(game_entry) => Ok(Some(game_entry)),
        None => Ok(None),
    }
}

/// Reconciliation task structure.
struct MatchingTask {
    store_entry: StoreEntry,
    igdb: Arc<IgdbApi>,
    steam: Arc<SteamDataApi>,
    tx: mpsc::Sender<ReconMatch>,
}
