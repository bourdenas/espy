use std::time::{Duration, SystemTime};

use clap::Parser;
use espy_server::{api, games, library::firestore, util, Tracing};
use tracing::{error, info};

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
    Tracing::setup("utils/game_retrieval")?;

    let opts: Opts = Opts::parse();
    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    let steam = games::SteamDataApi::new();

    let mut firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");
    let next_refresh = SystemTime::now()
        .checked_add(Duration::from_secs(30 * 60))
        .unwrap();

    for i in 0.. {
        let games = igdb.get_igdb_games(i).await?;
        if games.len() == 0 {
            break;
        }
        info!("{}:{}", i * 500, i * 500 + games.len() as u64);

        for igdb_game in games {
            let mut game_entry = match igdb.resolve(igdb_game).await {
                Ok(game_entry) => game_entry,
                Err(e) => {
                    error!("{e}");
                    continue;
                }
            };

            if let Err(e) = steam.retrieve_steam_data(&mut game_entry).await {
                error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
            }

            if next_refresh < SystemTime::now() {
                firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
                    .expect("FirestoreApi.from_credentials()");
            }

            if let Err(e) = firestore::games::write(&firestore, &game_entry) {
                error!("Failed to save '{}' in Firestore: {e}", game_entry.name);
            }
            info!("Resolved '{}' ({})", game_entry.name, game_entry.id);
        }
    }

    Ok(())
}
