// Declare the modules created from protbufs.
mod espy {
    include!(concat!(env!("OUT_DIR"), "/espy.rs"));
}
mod igdb {
    include!(concat!(env!("OUT_DIR"), "/igdb.rs"));
}

mod igdb_service;
mod library;
mod recon;
mod steam;
mod util;

const TEST_USER: &str = "testing";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let keys = util::keys::Keys::from_file("../server/keys.json").unwrap();

    let mut igdb = igdb_service::api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    let mut mgr = library::manager::LibraryManager::new(TEST_USER);
    mgr.build(
        steam::api::SteamApi::new(&keys.steam.client_key, &keys.steam.user_id),
        recon::reconciler::Reconciler::new(igdb),
    )
    .await?;

    println!(
        "entries: {}\nunreconciled entries: {}",
        mgr.library.entry.len(),
        mgr.library.unreconciled_steam_game.len()
    );

    Ok(())
}
