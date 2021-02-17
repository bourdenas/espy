// Declare the modules created from protbufs.
pub mod espy {
    include!(concat!(env!("OUT_DIR"), "/espy.rs"));
}
mod igdb {
    include!(concat!(env!("OUT_DIR"), "/igdb.rs"));
}

pub mod igdb_service;
pub mod library;
pub mod recon;
pub mod steam;
pub mod util;
