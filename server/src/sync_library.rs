use clap::Clap;
use espy_server::*;
use std::sync::{Arc, Mutex};

/// Espy server util for testing functionality of the backend.
#[derive(Clap)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    user: String,

    /// If set it tries to reconcile unknown entries with IGDB entries.
    #[clap(long)]
    recon: bool,

    /// If set it refreshes user's library with IGDB data.
    #[clap(long)]
    refresh: bool,

    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,

    /// SID token retrieved from Epic Game Store after authentication in
    /// https://www.epicgames.com/id/login?redirectUrl=https%3A%2F%2Fwww.epicgames.com%2Fid%2Fapi%2Fredirect
    #[clap(long)]
    egs_sid: Option<String>,

    /// JSON file containing Firestore credentials for espy service.
    #[clap(
        long,
        default_value = "espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json"
    )]
    firestore_credentials: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;
    let igdb = Arc::new(igdb);

    let firestore = Arc::new(Mutex::new(
        api::FirestoreApi::from_credentials(&opts.firestore_credentials)
            .expect("FirestoreApi.from_credentials()"),
    ));

    let mut user = library::User::new(Arc::clone(&firestore), &opts.user)?;
    user.sync(&keys, opts.egs_sid).await?;

    let mgr = library::LibraryManager::new(&opts.user, Arc::clone(&firestore));
    if opts.recon {
        mgr.match_entries(library::Reconciler::new(Arc::clone(&igdb)))
            .await?;
    }
    if opts.refresh {
        mgr.refresh_entries(library::Reconciler::new(Arc::clone(&igdb)))
            .await?;
    }

    Ok(())
}
