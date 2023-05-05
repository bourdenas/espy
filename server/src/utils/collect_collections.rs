use std::time::{Duration, SystemTime, UNIX_EPOCH};

use clap::Parser;
use espy_server::{
    api,
    documents::{GameDigest, IgdbCollection},
    games,
    library::firestore,
    util, Status, Tracing,
};
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

    /// Collect only game entries that were updated in the last N days.
    #[clap(long, default_value = "60")]
    updated_since: u64,

    #[clap(long, default_value = "0")]
    offset: u64,

    #[clap(long)]
    count: bool,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("utils/collect_collections")?;

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

    let updated_timestamp = SystemTime::now()
        .checked_sub(Duration::from_secs(24 * 60 * 60 * opts.updated_since))
        .unwrap()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();

    let mut k = opts.offset;
    for i in 0.. {
        let collections = igdb_batch
            .collect_collections(updated_timestamp, opts.offset + i * 500)
            .await?;
        if collections.len() == 0 {
            break;
        }
        info!(
            "\nWorking on {}:{}",
            opts.offset + i * 500,
            opts.offset + i * 500 + collections.len() as u64
        );

        if opts.count {
            continue;
        }

        for collection in collections {
            let mut igdb_collection = IgdbCollection {
                id: collection.id,
                name: collection.name,
                slug: collection.slug,
                url: collection.url,
                games: vec![],
            };

            for game in &collection.games {
                match firestore::games::read(&firestore, *game) {
                    Ok(game_entry) => igdb_collection.games.push(GameDigest::new(game_entry)),
                    Err(Status::NotFound(_)) => {
                        let igdb_game = match igdb.get(*game).await {
                            Ok(game) => game,
                            Err(e) => {
                                error!("{e}");
                                continue;
                            }
                        };

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

                        if let Err(e) = firestore::games::write(&firestore, &game_entry) {
                            error!("Failed to save '{}' in Firestore: {e}", game_entry.name);
                        }
                        info!("#{} Resolved '{}' ({})", k, game_entry.name, game_entry.id);
                        igdb_collection.games.push(GameDigest::new(game_entry))
                    }
                    Err(e) => error!("Failed to read from Firestore game with id={game}: {e}"),
                }
            }

            if !igdb_collection.games.is_empty() {
                if let Err(e) = firestore::collections::write(&firestore, &igdb_collection) {
                    error!(
                        "Failed to save '{}' in Firestore: {e}",
                        &igdb_collection.name
                    );
                }
                info!("#{} Saved collection '{}'", k, igdb_collection.name);
            }
            k += 1;

            if next_refresh < SystemTime::now() {
                info!("Refreshing Firestore credentials...");
                firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
                    .expect("FirestoreApi.from_credentials()");

                next_refresh = SystemTime::now()
                    .checked_add(Duration::from_secs(30 * 60))
                    .unwrap();
            }
        }
    }

    Ok(())
}
