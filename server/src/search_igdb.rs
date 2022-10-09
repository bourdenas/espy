use clap::Parser;
use espy_server::{documents::StoreEntry, library::search, *};
use itertools::Itertools;

/// IGDB search utility.
#[derive(Parser)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    search: String,

    #[clap(long, default_value = "")]
    external: String,

    #[clap(long, default_value = "")]
    external_store: String,

    #[clap(long)]
    expand: bool,

    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("search-igdb")?;

    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    if !&opts.external.is_empty() {
        let game = igdb
            .match_store_entry(&StoreEntry {
                id: opts.external,
                storefront_name: opts.external_store,
                ..Default::default()
            })
            .await?;
        println!("Got: {:?}", game);
        return Ok(());
    }

    let games = search::get_candidates(&igdb, &opts.search).await?;
    println!(
        "Found {} candidates.\n{}",
        games.len(),
        games.iter().map(|game| &game.name).join("\n")
    );

    if opts.expand && !games.is_empty() {
        let game = igdb.get_game_by_id(games[0].id).await?.unwrap();
        println!("{:#?}", game);
    }

    Ok(())
}
