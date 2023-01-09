use clap::Parser;
use espy_server::{api::FirestoreApi, Status, Tracing};
use tracing::instrument;

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

#[instrument(level = "trace", skip(_firestore))]
fn refresh_library_entries(_firestore: &FirestoreApi, user_id: &str) -> Result<(), Status> {
    Ok(())
}
