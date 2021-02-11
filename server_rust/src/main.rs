// Declare the modules created from protbufs.
mod espy {
    include!(concat!(env!("OUT_DIR"), "/espy.rs"));
}
mod igdb {
    include!(concat!(env!("OUT_DIR"), "/igdb.rs"));
}

mod library;

static TEST_USER: &'static str = "testing";

#[tokio::main]
async fn main() {
    let mgr = library::manager::LibraryManager::new_async(TEST_USER).await;
    println!("espy\n{:#?}", mgr.library.unreconciled_steam_game);
}
