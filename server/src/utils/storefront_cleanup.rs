use clap::Parser;
use espy_server::{
    api::FirestoreApi,
    documents::{LibraryEntry, StoreEntry},
    library::LibraryOps,
    Tracing,
};

#[derive(Parser)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    user: String,

    /// JSON file containing Firestore credentials for espy service.
    #[clap(
        long,
        default_value = "espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json"
    )]
    firestore_credentials: String,
}

/// Verifies that all game ids that exist in in /users/{id}/strorefront/{store}
/// document are also included in the user library of matched or failed entries.
/// If a game id is missing from the library it is deleted in order to be picked
/// up again for recon on the next storefront sync.
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("util/storefront_cleanup")?;

    let opts: Opts = Opts::parse();

    let firestore = FirestoreApi::from_credentials(&opts.firestore_credentials)
        .expect("FirestoreApi.from_credentials()");

    let user_library = LibraryOps::list_library(&firestore, &opts.user)?;
    let failed = LibraryOps::list_failed(&firestore, &opts.user)?;

    storefront_cleanup(&firestore, &opts.user, &user_library, &failed, "gog");
    storefront_cleanup(&firestore, &opts.user, &user_library, &failed, "steam");

    Ok(())
}

fn storefront_cleanup(
    firestore: &FirestoreApi,
    user_id: &str,
    user_library: &[LibraryEntry],
    user_failed: &[StoreEntry],
    storefront_name: &str,
) {
    let mut owned_games = LibraryOps::read_storefront_ids(&firestore, user_id, storefront_name);

    let mut missing = vec![];
    for game_id in &owned_games {
        let iter = user_library
            .iter()
            .find(|entry| find_store_entry(entry, game_id, storefront_name));
        if let None = iter {
            let iter = user_failed
                .iter()
                .find(|entry| entry.id == *game_id && entry.storefront_name == storefront_name);

            if let None = iter {
                missing.push(game_id.clone());
            }
        }
    }
    println!(
        "Missing {} {storefront_name} games from user library\nids={:?}",
        missing.len(),
        missing
    );
    owned_games.retain(|e| !missing.contains(&e));
    LibraryOps::write_storefront_ids(firestore, user_id, storefront_name, owned_games)
        .expect("Failed to write StorefrontIds for {storefront_name}");
}

fn find_store_entry(library_entry: &LibraryEntry, id: &str, store_name: &str) -> bool {
    library_entry
        .store_entries
        .iter()
        .find(|entry| entry.id == id && entry.storefront_name == store_name)
        .is_some()
}
