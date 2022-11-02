use clap::Parser;
use espy_server::{
    api::{FirestoreApi, IgdbApi},
    documents::GameEntry,
    library::{steam_data, LibraryOps},
    *,
};
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;
use tracing::{error, info, trace_span, warn, Instrument};

/// Espy util for refreshing IGDB and Steam data for GameEntries.
#[derive(Parser)]
struct Opts {
    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,

    /// JSON file containing Firestore credentials for espy service.
    #[clap(
        long,
        default_value = "espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json"
    )]
    firestore_credentials: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("utils/refresh_entries")?;

    let opts: Opts = Opts::parse();
    let firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();
    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    refresh_entries(&firestore, igdb).await?;

    Ok(())
}

/// Refreshes game entries info from IGDB in user's library.
// #[instrument(
//     level = "trace",
//     skip(self, recon_service),
//     fields(user_id = %self.user_id),
// )]
async fn refresh_entries(firestore: &FirestoreApi, igdb: IgdbApi) -> Result<(), Status> {
    let game_entries = LibraryOps::list_games(firestore)?;

    let igdb = Arc::new(igdb);
    let (tx, rx) = mpsc::channel(32);
    let _handle = tokio::spawn(
        async move {
            let fut = stream::iter(game_entries.into_iter().map(|game_entry| RefreshTask {
                game_entry,
                igdb: Arc::clone(&igdb),
                tx: tx.clone(),
            }))
            .for_each_concurrent(2, refresh_task)
            .instrument(trace_span!("spawn refresh tasks"));

            fut.await;
            drop(tx);
        }
        .instrument(trace_span!("spawn refresh task")),
    );

    receive_games(firestore, rx).await;

    Ok(())
}

struct RefreshTask {
    game_entry: GameEntry,
    igdb: Arc<IgdbApi>,
    tx: mpsc::Sender<GameEntry>,
}

async fn refresh_task(task: RefreshTask) {
    info!("Refreshing '{}'", &task.game_entry.name);

    let game_entry = match task.igdb.get_game_by_id(task.game_entry.id).await {
        Ok(game_entry) => match game_entry {
            Some(game_entry) => game_entry,
            None => {
                error!(
                    "Failed to refresh '{}': IGDB game with {} was not fonud.",
                    task.game_entry.name, task.game_entry.id
                );
                task.game_entry
            }
        },
        Err(e) => {
            error!("Failed to refresh '{}': {e}", task.game_entry.name);
            task.game_entry
        }
    };

    if let Err(e) = task.tx.send(game_entry).await {
        error!("{e}");
    }
}

async fn receive_games(firestore: &FirestoreApi, mut rx: mpsc::Receiver<GameEntry>) {
    while let Some(mut game_entry) = rx.recv().await {
        if let Err(e) = steam_data::retrieve_steam_data(&mut game_entry).await {
            error!("{e}");
            warn!(
                "Skipping update of '{}' due to failing to retrieve Steam data.",
                game_entry.name
            );
        }
        LibraryOps::write_game_entry(firestore, &game_entry)
            .expect("Firestore update_library_entry():");
    }
}
