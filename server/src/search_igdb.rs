use clap::Parser;
use espy_server::{documents::StoreEntry, *};

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

    #[clap(long)]
    examine: bool,

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

    let igdb_games = igdb.search_by_title(&opts.search).await?;
    println!("Found {} candidates.", igdb_games.len());

    for game in &igdb_games {
        println!("'{}'", &game.name);
    }
    if opts.examine && !igdb_games.is_empty() {
        let game = igdb.get_game_by_id(igdb_games[0].id).await?.unwrap();
        println!("{:#?}", game);
    }
    if opts.expand && !igdb_games.is_empty() {
        let igdb_game = &igdb_games[0];
        let game = igdb
            .get_game_by_id(match igdb_game.parent_game {
                Some(parent) => parent,
                None => match igdb_game.version_parent {
                    Some(parent) => parent,
                    None => igdb_game.id,
                },
            })
            .await?
            .unwrap();
        println!("{:#?}", game);
    }

    Ok(())
}
