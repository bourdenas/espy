use clap::Parser;
use espy_server::{api, documents::ExternalGame, library::firestore, util, Tracing};
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
    offset: u64,

    #[clap(long)]
    store: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("utils/collect_external_games")?;

    let opts: Opts = Opts::parse();
    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;
    let igdb_batch = api::IgdbBatchApi::new(igdb.clone());

    let firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let mut k = opts.offset;
    for i in 0.. {
        let external_games = igdb_batch
            .collect_external_games(&opts.store, opts.offset + i * 500)
            .await?;
        if external_games.len() == 0 {
            break;
        }
        info!(
            "\nWorking on {}:{}",
            opts.offset + i * 500,
            opts.offset + i * 500 + external_games.len() as u64
        );

        for external_game in external_games {
            let external_game =
                ExternalGame::new(external_game.game, external_game.uid, external_game.url);
            if let Err(e) =
                firestore::external_games::write(&firestore, &opts.store, &external_game)
            {
                error!(
                    "Failed to save '{}_{}' in Firestore: {e}",
                    &opts.store, external_game.store_id
                );
            }
            k += 1;
        }
    }
    info!("Collected {k} external game mappings for {}", &opts.store);

    Ok(())
}
