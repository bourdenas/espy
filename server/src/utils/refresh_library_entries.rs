use std::sync::Arc;

use clap::Parser;
use espy_server::{
    api::{FirestoreApi, IgdbApi},
    documents::{Library, LibraryEntry},
    library, util, Status, Tracing,
};
use tracing::{error, info, instrument};

/// Espy util for refreshing IGDB and Steam data for GameEntries.
#[derive(Parser)]
struct Opts {
    #[clap(long)]
    user: String,

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
    Tracing::setup("utils/refresh_library_entries")?;

    let opts: Opts = Opts::parse();
    let firestore = FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();
    let mut igdb = IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    refresh_library_entries(Arc::new(firestore), igdb, &opts.user).await?;

    Ok(())
}

#[instrument(level = "trace", skip(firestore, igdb, user_id))]
async fn refresh_library_entries(
    firestore: Arc<FirestoreApi>,
    igdb: IgdbApi,
    user_id: &str,
) -> Result<(), Status> {
    let legacy_library = library::firestore::library::read(&firestore, user_id)?;
    info!("updating {} titles...", legacy_library.entries.len());

    let mut library = Library { entries: vec![] };
    for entry in legacy_library.entries {
        match library::firestore::games::read(&firestore, entry.id) {
            Ok(game_entry) => {
                info!("updated from firestore '{title}'", title = game_entry.name);
                library
                    .entries
                    .push(LibraryEntry::new(game_entry, entry.store_entries))
            }
            Err(e) => {
                error!("Failed to read: {e}");
                let igdb_game = match igdb.get(entry.id).await {
                    Ok(game) => game,
                    Err(e) => {
                        error!("Failed to igdb.get: {e}");
                        continue;
                    }
                };
                let game_entry = match igdb.resolve(igdb_game).await {
                    Ok(game) => game,
                    Err(e) => {
                        error!("Failed to igdb.resolve: {e}");
                        continue;
                    }
                };
                library::firestore::games::write(&firestore, &game_entry)?;

                info!("resolved from igdb '{title}'", title = game_entry.name);
                library
                    .entries
                    .push(LibraryEntry::new(game_entry, entry.store_entries))
            }
        }
    }

    library::firestore::library::write(&firestore, user_id, &library)?;
    let serialized = serde_json::to_string(&library)?;
    info!("updated library size: {}KB", serialized.len() / 1024);

    Ok(())
}
