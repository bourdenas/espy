// Declare the modules created from protbufs.
pub mod espy {
    tonic::include_proto!("espy");
}
mod igdb {
    tonic::include_proto!("igdb");
}

pub mod api;
pub mod handler;
pub mod http;
pub mod library;
pub mod models;
pub mod traits;
pub mod util;

mod status;
pub use status::Status;
