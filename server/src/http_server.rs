use crate::api::{FirestoreApi, IgdbApi};
use crate::http;
use clap::Parser;
use espy_server::*;
use std::env;
use std::sync::{Arc, Mutex};
use warp::{self, Filter};

#[derive(Parser)]
struct Opts {
    /// JSON file containing application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,

    /// JSON file containing Firestore credentials for espy service.
    #[clap(
        long,
        default_value = "espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json"
    )]
    firestore_credentials: String,

    /// Port number to use for listening to gRPC requests.
    #[clap(short, long, default_value = "8080")]
    port: u16,
}

#[tokio::main]
async fn main() -> Result<(), Status> {
    let subscriber = tracing_subscriber::FmtSubscriber::new();
    match tracing::subscriber::set_global_default(subscriber) {
        Ok(()) => (),
        Err(e) => eprintln!("{e}"),
    };

    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    let mut igdb = IgdbApi::new(&keys.igdb.client_id, &keys.igdb.secret);
    igdb.connect().await?;

    let firestore = Arc::new(Mutex::new(
        FirestoreApi::from_credentials(&opts.firestore_credentials)
            .expect("FirestoreApi.from_credentials()"),
    ));

    // Let ENV VAR override flag.
    let port: u16 = match env::var("PORT") {
        Ok(port) => match port.parse::<u16>() {
            Ok(port) => port,
            Err(_) => opts.port,
        },
        Err(_) => opts.port,
    };

    println!("starting the HTTP server listening at port {port}");
    warp::serve(
        http::routes::routes(Arc::new(keys), Arc::new(igdb), firestore).with(
            warp::cors()
                .allow_methods(vec!["GET", "POST"])
                .allow_headers(vec!["Content-Type", "Authorization"])
                .allow_any_origin()
                .allow_credentials(true),
        ),
    )
    .run(([0, 0, 0, 0], opts.port))
    .await;

    Ok(())
}
