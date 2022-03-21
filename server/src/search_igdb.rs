use clap::Clap;
use documents::GameEntry;
use espy_server::*;

/// IGDB search utility.
#[derive(Clap)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    search: String,

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
    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    let mut result = igdb.search_by_title(&opts.search).await?;
    println!("Found {} candidates.", result.games.len());
    for game in &result.games {
        println!("'{}'", &game.name);
    }
    if opts.examine && !result.games.is_empty() {
        let game = igdb.get_game_by_id(result.games[0].id).await?.unwrap();
        println!("{:#?}", game);
    }
    if opts.expand && !result.games.is_empty() {
        let game_entry = GameEntry::new(std::mem::take(&mut result.games[0]));
        let game = igdb
            .get_game_by_id(match game_entry.parent {
                Some(parent_id) => parent_id,
                None => game_entry.id,
            })
            .await?
            .unwrap();
        println!("{:#?}", GameEntry::new(game));
    }

    Ok(())
}
