// Declare the modules created from protbufs.
mod espy {
    include!(concat!(env!("OUT_DIR"), "/espy.rs"));
}
mod igdb {
    include!(concat!(env!("OUT_DIR"), "/igdb.rs"));
}

mod library;
mod steam;
mod util;

static TEST_USER: &'static str = "testing";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let mgr = library::manager::LibraryManager::new_async(TEST_USER).await;
    println!(
        "entries: {}\nunreconciled entries: {}",
        mgr.library.entry.len(),
        mgr.library.unreconciled_steam_game.len()
    );

    let keys = util::keys::Keys::from_file("../server/keys.json").unwrap();

    let steam = steam::api::SteamApi::new(&keys.steam.client_key, &keys.steam.user_id);
    let steam_list = steam.get_owned_games().await?;
    println!("steam_list: {}", steam_list.game.len());

    Ok(())
}
