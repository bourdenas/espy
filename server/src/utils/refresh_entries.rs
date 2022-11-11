use clap::Parser;
use espy_server::{
    api::{FirestoreApi, IgdbApi},
    documents::GameEntry,
    library::{LibraryOps, Reconciler, SteamDataApi},
    *,
};
use futures::stream::{self, StreamExt};
use std::sync::Arc;
use tokio::sync::mpsc;
use tracing::{error, info, instrument, trace_span, Instrument};

/// Espy util for refreshing IGDB and Steam data for GameEntries.
#[derive(Parser)]
struct Opts {
    /// JSON file that contains application keys for espy service.
    #[clap(long)]
    id: Option<u64>,

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
    let firestore = FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();
    let mut igdb = IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;
    let steam = SteamDataApi::new();

    if let Some(id) = opts.id {
        refresh_game(id, &firestore, igdb, steam).await?;
    } else {
        refresh_entries(&firestore, igdb, steam).await?;
    }

    Ok(())
}

async fn refresh_game(
    id: u64,
    firestore: &FirestoreApi,
    igdb: IgdbApi,
    steam: SteamDataApi,
) -> Result<(), Status> {
    let game = LibraryOps::read_game_entry(firestore, id)?;
    refresh(vec![game], firestore, igdb, steam).await
}

#[instrument(level = "trace", skip(firestore, igdb, steam))]
async fn refresh_entries(
    firestore: &FirestoreApi,
    igdb: IgdbApi,
    steam: SteamDataApi,
) -> Result<(), Status> {
    let game_entries = LibraryOps::list_games(firestore)?;
    refresh(game_entries, firestore, igdb, steam).await
}

async fn refresh(
    game_entries: Vec<GameEntry>,
    firestore: &FirestoreApi,
    igdb: IgdbApi,
    steam: SteamDataApi,
) -> Result<(), Status> {
    let igdb = Arc::new(igdb);
    let steam = Arc::new(steam);
    let (tx, rx) = mpsc::channel(32);
    let _handle = tokio::spawn(
        async move {
            let fut = stream::iter(game_entries.into_iter().map(|game_entry| RefreshTask {
                game_entry,
                igdb: Arc::clone(&igdb),
                steam: Arc::clone(&steam),
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
    steam: Arc<SteamDataApi>,
    tx: mpsc::Sender<GameEntry>,
}

async fn refresh_task(task: RefreshTask) {
    info!("Refreshing '{}'", &task.game_entry.name);

    let recon_service = Reconciler::new(task.igdb, task.steam);

    let game_entry = match recon_service.resolve(task.game_entry.id).await {
        Ok(game_entry) => Some(game_entry),
        Err(e) => {
            error!("Failed to refresh '{}': {e}", task.game_entry.name);
            None
        }
    };

    if let Some(game_entry) = game_entry {
        if let Err(e) = task.tx.send(game_entry).await {
            error!("{e}");
        }
    }
}

async fn receive_games(firestore: &FirestoreApi, mut rx: mpsc::Receiver<GameEntry>) {
    while let Some(game_entry) = rx.recv().await {
        info!("Updating '{}'", game_entry.name);
        LibraryOps::write_game_entry(firestore, &game_entry).expect(&format!(
            "Firestore write_game_entry('{}'):",
            game_entry.name
        ));
    }
}
