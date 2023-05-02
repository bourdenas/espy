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

    #[clap(long, default_value = "0")]
    updated_since: u64,

    #[clap(long, default_value = "0")]
    offset: u64,

    #[clap(long)]
    count: bool,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("utils/collect_games")?;

    let opts: Opts = Opts::parse();
    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;
    let igdb_batch = api::IgdbBatchApi::new(igdb.clone());

    let steam = games::SteamDataApi::new();

    let mut firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");
    let mut next_refresh = SystemTime::now()
        .checked_add(Duration::from_secs(30 * 60))
        .unwrap();

    let mut k = opts.offset;
    for i in 0.. {
        let games = igdb_batch
            .collect_igdb_games(opts.updated_since, opts.offset + i * 500)
            .await?;
        if games.len() == 0 {
            break;
        }
        info!(
            "\nWorking on {}:{}",
            opts.offset + i * 500,
            opts.offset + i * 500 + games.len() as u64
        );

        if opts.count {
            continue;
        }

        for igdb_game in games {
            let mut game_entry = match igdb.resolve(igdb_game).await {
                Ok(game_entry) => game_entry,
                Err(e) => {
                    error!("{e}");
                    k += 1;
                    continue;
                }
            };

            if let Err(e) = steam.retrieve_steam_data(&mut game_entry).await {
                error!("Failed to retrieve SteamData for '{}' {e}", game_entry.name);
            }

            if next_refresh < SystemTime::now() {
                info!("Refreshing Firestore credentials...");
                firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
                    .expect("FirestoreApi.from_credentials()");

                next_refresh = SystemTime::now()
                    .checked_add(Duration::from_secs(30 * 60))
                    .unwrap();
            }

            if let Err(e) = firestore::games::write(&firestore, &game_entry) {
                error!("Failed to save '{}' in Firestore: {e}", game_entry.name);
            }
            info!("#{} Resolved '{}' ({})", k, game_entry.name, game_entry.id);
            k += 1;
        }
    }

    Ok(())
}
