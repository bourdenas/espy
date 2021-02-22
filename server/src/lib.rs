// Declare the modules created from protbufs.
pub mod espy {
    tonic::include_proto!("espy");
}
mod igdb {
    tonic::include_proto!("igdb");
}

pub mod igdb_service;
pub mod library;
pub mod recon;
pub mod steam;
pub mod util;
