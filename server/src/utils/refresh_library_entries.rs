use clap::Parser;
use espy_server::{
    api::FirestoreApi,
    documents::{Library, LibraryEntry},
    library, Status, Tracing,
};
use tracing::{error, info, instrument};

/// Espy util for refreshing IGDB and Steam data for GameEntries.
#[derive(Parser)]
struct Opts {
    #[clap(long)]
    user: String,

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

    refresh_library_entries(&firestore, &opts.user)?;

    Ok(())
}

#[instrument(level = "trace", skip(firestore))]
fn refresh_library_entries(firestore: &FirestoreApi, user_id: &str) -> Result<(), Status> {
    let library = library::firestore::library::read(firestore, user_id)?;
    info!("updating {} titles...", library.entries.len());

    let library = Library {
        entries: library
            .entries
            .into_iter()
            .map(
                |entry| match library::firestore::games::read(firestore, entry.id) {
                    Ok(game_entry) => {
                        info!("updated '{title}'", title = game_entry.name);
                        LibraryEntry::new(game_entry, entry.store_entries, entry.owned_versions)
                    }
                    Err(e) => {
                        error!("{e}");
                        entry
                    }
                },
            )
            .collect(),
    };
    library::firestore::library::write(firestore, user_id, &library)?;
    let serialized = serde_json::to_string(&library)?;
    info!("updated library size: {}KB", serialized.len() / 1024);

    Ok(())
}
