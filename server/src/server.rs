use clap::Clap;
use espy_server::*;

/// Espy server util for testing functionality of the backend.
#[derive(Clap)]
struct Opts {
    /// JSON file that contains application keys for espy service.
    #[clap(long, default_value = "keys.json")]
    key_store: String,
    /// Port number to use for listening to gRPC requests.
    #[clap(short, long, default_value = "6235")]
    port: u16,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let opts: Opts = Opts::parse();

    let keys = util::keys::Keys::from_file(&opts.key_store).unwrap();

    println!("starting the server...");
    tonic::transport::Server::builder()
        .add_service(EspyServer::new(EspyImpl::new(keys)))
        .serve(format!("[::1]:{}", opts.port).parse()?)
        .await?;

    Ok(())
}

use espy::espy_server::{Espy, EspyServer};

pub struct EspyImpl {
    keys: util::keys::Keys,
}

impl EspyImpl {
    fn new(keys: util::keys::Keys) -> EspyImpl {
        EspyImpl { keys }
    }
}

#[tonic::async_trait]
impl Espy for EspyImpl {
    async fn get_library(
        &self,
        request: tonic::Request<espy::LibraryRequest>,
    ) -> Result<tonic::Response<espy::LibraryResponse>, tonic::Status> {
        println!("Request: {:?}", request.get_ref());
        Ok(tonic::Response::new(espy::LibraryResponse::default()))
    }
}
