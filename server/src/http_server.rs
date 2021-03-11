use crate::http;
use crate::igdb_service::api::IgdbApi;
use clap::Clap;
use espy_server::*;
use std::sync::Arc;

#[derive(Clap)]
struct Opts {
    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,
    /// Port number to use for listening to gRPC requests.
    #[clap(short, long, default_value = "3030")]
    port: u16,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;
    let igdb = Arc::new(igdb);

    println!("starting the HTTP server...");
    warp::serve(http::routes::routes(igdb))
        .run(([127, 0, 0, 1], opts.port))
        .await;

    Ok(())
}
