mod backend;
mod batch;
mod connection;
mod docs;
mod ranking;
mod resolve;
mod service;

pub use batch::IgdbBatchApi;
use connection::IgdbConnection;
pub use docs::IgdbGame;
pub use service::IgdbApi;
