use clap::Parser;
use espy_server::{games::Resolver, *};
use std::sync::{Arc, Mutex};
use tracing::{error, instrument};

/// Espy util for refreshing IGDB and Steam data for GameEntries.
#[derive(Parser)]
struct Opts {
    /// Refresh only game with specified id.
    #[clap(long)]
    id: Option<u64>,

    /// If set, delete game entry instead of refreshing it.
    #[clap(long)]
    delete: bool,

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
    let steam = games::SteamDataApi::new();

    if let Some(id) = opts.id {
        match opts.delete {
            false => refresh_game(id, firestore, igdb, steam).await?,
            true => library::firestore::games::delete(&firestore, id)?,
        }
    } else {
        refresh_entries(firestore, igdb, steam).await?;
    }

    Ok(())
}

async fn refresh_game(
    id: u64,
    firestore: api::FirestoreApi,
    igdb: api::IgdbApi,
    steam: games::SteamDataApi,
) -> Result<(), Status> {
    let game = library::firestore::games::read(&firestore, id)?;
    refresh(vec![game], firestore, igdb, steam).await
}

#[instrument(level = "trace", skip(firestore, igdb, steam))]
async fn refresh_entries(
    firestore: api::FirestoreApi,
    igdb: api::IgdbApi,
    steam: games::SteamDataApi,
) -> Result<(), Status> {
    let game_entries = library::firestore::games::list(&firestore)?;
    refresh(game_entries, firestore, igdb, steam).await
}

async fn refresh(
    game_entries: Vec<documents::GameEntry>,
    firestore: api::FirestoreApi,
    igdb: api::IgdbApi,
    steam: games::SteamDataApi,
) -> Result<(), Status> {
    let firestore = Arc::new(Mutex::new(firestore));

    for game_entry in game_entries {
        if let Err(e) =
            Resolver::resolve(game_entry.id, &igdb, &steam, Arc::clone(&firestore)).await
        {
            error!("Failed to refresh '{}': {e}", game_entry.name);
        }
    }

    Ok(())
}
