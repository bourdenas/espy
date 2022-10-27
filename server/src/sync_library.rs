use clap::Parser;
use espy_server::*;
use std::sync::{Arc, Mutex};
use tracing::trace_span;

/// Espy server util for testing functionality of the backend.
#[derive(Parser)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    user: String,

    /// If set it refreshes user's library with IGDB data.
    #[clap(long)]
    refresh: bool,

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
    Tracing::setup("sync-library")?;

    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;
    let igdb = Arc::new(igdb);

    let firestore = Arc::new(Mutex::new(
        api::FirestoreApi::from_credentials(&opts.firestore_credentials)
            .expect("FirestoreApi.from_credentials()"),
    ));

    let span = trace_span!("library sync");
    let _guard = span.enter();

    let mut user = library::User::new(Arc::clone(&firestore), &opts.user)?;
    user.sync(&keys, library::Reconciler::new(Arc::clone(&igdb)))
        .await?;

    // if opts.refresh {
    //     let mgr = library::LibraryManager::new(&opts.user, Arc::clone(&firestore));
    //     mgr.refresh_entries(library::Reconciler::new(Arc::clone(&igdb)))
    //         .await?;
    // }

    Ok(())
}
