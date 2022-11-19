use clap::Parser;
use espy_server::{api::FirestoreApi, documents::UserTags, library::LibraryOps, *};
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

    extract_user_tags(&firestore, &opts.user)?;

    Ok(())
}

#[instrument(level = "trace", skip(firestore))]
fn extract_user_tags(firestore: &FirestoreApi, user_id: &str) -> Result<(), Status> {
    let library_entries = LibraryOps::list_library(firestore, user_id)?;

    let mut user_tags = UserTags { tags: vec![] };
    for entry in library_entries {
        if let Some(data) = entry.user_data {
            for tag in data.tags {
                user_tags.add(entry.id, tag);
            }
        }
    }

    LibraryOps::write_user_tags(firestore, user_id, &user_tags)?;

    Ok(())
}
