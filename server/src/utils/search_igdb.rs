use clap::Parser;
use espy_server::{documents::StoreEntry, *};
use itertools::Itertools;

/// IGDB search utility.
#[derive(Parser)]
struct Opts {
    /// Game title to search for in IGDB.
    #[clap(short, long, default_value = "")]
    search: String,

    /// External store ID used for retrieving game info.
    #[clap(long, default_value = "")]
    external: String,

    /// If external is set thhis indicates the store name to be used.
    #[clap(long, default_value = "")]
    external_store: String,

    /// If set retrieves all available information for the top candidate of the
    /// search.
    #[clap(long)]
    expand: bool,

    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,
}

/// Quickly retrieve game info from IGDB based on title or external id matching.
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("utils/search_igdb")?;

    let opts: Opts = Opts::parse();
    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = api::IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    if !&opts.external.is_empty() {
        let game = igdb
            .get_by_store_entry(&StoreEntry {
                id: opts.external,
                storefront_name: opts.external_store,
                ..Default::default()
            })
            .await?;
        println!("Got: {:?}", game);
        return Ok(());
    }

    let games = igdb.search_by_title(&opts.search).await?;
    println!(
        "Found {} candidates.\n{}",
        games.len(),
        games.iter().map(|game| &game.name).join("\n")
    );

    if opts.expand && !games.is_empty() {
        todo!("implement game resolution")
    }

    Ok(())
}
