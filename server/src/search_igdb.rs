use clap::Clap;
use espy_server::*;

/// IGDB search utility.
#[derive(Clap)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    search: String,

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

    let result = igdb.search_by_title(&opts.search).await?;
    println!("{:#?}", result.games[0]);

    Ok(())
}
