use clap::Parser;
use espy_server::{
    documents::{GameDigest, IgdbCollection},
    *,
};
use std::time::{Duration, SystemTime};
use tracing::{info, instrument};

/// Espy util for refreshing IGDB and Steam data for GameEntries.
#[derive(Parser)]
struct Opts {
    /// Refresh only game with specified id.
    #[clap(long)]
    id: Option<u64>,

    /// If set, delete game entry instead of refreshing it.
    #[clap(long)]
    delete: bool,

    /// JSON file containing Firestore credentials for espy service.
    #[clap(
        long,
        default_value = "espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json"
    )]
    firestore_credentials: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("utils/refresh_collections")?;

    let opts: Opts = Opts::parse();

    if let Some(id) = opts.id {
        match opts.delete {
            false => refresh_collection(id, &opts.firestore_credentials).await?,
            true => {
                let firestore = api::FirestoreApi::from_credentials(&opts.firestore_credentials)
                    .expect("FirestoreApi.from_credentials()");
                library::firestore::collections::delete(&firestore, id)?
            }
        }
    } else {
        refresh_collections(&opts.firestore_credentials).await?;
    }

    Ok(())
}

async fn refresh_collection(id: u64, firestore_credentials: &str) -> Result<(), Status> {
    let firestore = api::FirestoreApi::from_credentials(firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let collection = library::firestore::collections::read(&firestore, id)?;
    refresh(vec![collection], firestore_credentials)
}

#[instrument(level = "trace", skip(firestore_credentials))]
async fn refresh_collections(firestore_credentials: &str) -> Result<(), Status> {
    let firestore = api::FirestoreApi::from_credentials(firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let collections = library::firestore::collections::list(&firestore)?;
    refresh(collections, firestore_credentials)
}

fn refresh(collections: Vec<IgdbCollection>, firestore_credentials: &str) -> Result<(), Status> {
    let mut firestore = api::FirestoreApi::from_credentials(firestore_credentials)
        .expect("FirestoreApi.from_credentials()");
    let next_refresh = SystemTime::now()
        .checked_add(Duration::from_secs(30 * 60))
        .unwrap();

    info!("Updating {} collections...", collections.len());

    for collection in collections {
        if next_refresh < SystemTime::now() {
            firestore = api::FirestoreApi::from_credentials(firestore_credentials)
                .expect("FirestoreApi.from_credentials()");
        }

        let game_digest = collection
            .games
            .into_iter()
            .map(|digest| library::firestore::games::read(&firestore, digest.id))
            .filter_map(|e| e.ok())
            .map(|game_entry| GameDigest::new(game_entry))
            .collect();
        let collection = IgdbCollection {
            id: collection.id,
            name: collection.name,
            slug: collection.slug,
            url: collection.url,
            games: game_digest,
        };
        library::firestore::collections::write(&firestore, &collection)?;
    }

    Ok(())
}
