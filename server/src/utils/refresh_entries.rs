use clap::Parser;
use espy_server::*;
use std::{
    sync::{Arc, Mutex},
    time::{Duration, SystemTime},
};
use tracing::{error, info, instrument};

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
    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    let steam = games::SteamDataApi::new();

    if let Some(id) = opts.id {
        match opts.delete {
            false => refresh_game(id, &opts.firestore_credentials, igdb, steam).await?,
            true => {
                let firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
                    .expect("FirestoreApi.from_credentials()");
                library::firestore::games::delete(&firestore, id)?
            }
        }
    } else {
        refresh_entries(&opts.firestore_credentials, igdb, steam).await?;
    }

    Ok(())
}

async fn refresh_game(
    id: u64,
    firestore_credentials: &str,
    igdb: api::IgdbApi,
    steam: games::SteamDataApi,
) -> Result<(), Status> {
    let firestore = api::FirestoreApi::from_credentials(firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let game = library::firestore::games::read(&firestore, id)?;
    refresh(vec![game], firestore_credentials, igdb, steam).await
}

#[instrument(level = "trace", skip(firestore_credentials, igdb, steam))]
async fn refresh_entries(
    firestore_credentials: &str,
    igdb: api::IgdbApi,
    steam: games::SteamDataApi,
) -> Result<(), Status> {
    let firestore = api::FirestoreApi::from_credentials(firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let game_entries = library::firestore::games::list(&firestore)?;
    refresh(game_entries, firestore_credentials, igdb, steam).await
}

async fn refresh(
    game_entries: Vec<documents::GameEntry>,
    firestore_credentials: &str,
    igdb: api::IgdbApi,
    steam: games::SteamDataApi,
) -> Result<(), Status> {
    let mut firestore = Arc::new(Mutex::new(
        api::FirestoreApi::from_credentials(firestore_credentials)
            .expect("FirestoreApi.from_credentials()"),
    ));
    let next_refresh = SystemTime::now()
        .checked_add(Duration::from_secs(30 * 60))
        .unwrap();

    info!("Updating {} game entries...", game_entries.len());

    for game_entry in game_entries {
        if next_refresh < SystemTime::now() {
            firestore = Arc::new(Mutex::new(
                api::FirestoreApi::from_credentials(firestore_credentials)
                    .expect("FirestoreApi.from_credentials()"),
            ));
        }

        // if let Err(e) =
        //     Resolver::resolve(game_entry.id, &igdb, &steam, Arc::clone(&firestore)).await
        // {
        //     error!("Failed to refresh '{}': {e}", game_entry.name);
        // }
    }

    Ok(())
}
