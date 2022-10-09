use std::sync::Arc;

use clap::Parser;
use espy_server::{
    api::SteamApi,
    documents::{GameEntry, SteamData},
    *,
};
use futures::stream::{self, StreamExt};
use tracing::{error, info, instrument, log::warn};

/// Espy server util for testing functionality of the backend.
#[derive(Parser)]
struct Opts {
    /// Espy user name for managing a game library.
    #[clap(short, long, default_value = "")]
    user: String,

    /// JSON file containing Firestore credentials for espy service.
    #[clap(
        long,
        default_value = "espy-library-firebase-adminsdk-sncpo-3da8ca7f57.json"
    )]
    firestore_credentials: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    Tracing::setup("firestore_util")?;

    let opts: Opts = Opts::parse();

    let firestore = Arc::new(
        api::FirestoreApi::from_credentials(&opts.firestore_credentials)
            .expect("FirestoreApi.from_credentials()"),
    );

    let game_entries = read_game_entries(&firestore)?;

    let fut = stream::iter(game_entries.into_iter().map(|game_entry| SteamDataTask {
        game_entry,
        firestore: Arc::clone(&firestore),
    }))
    .for_each_concurrent(8, steam_data_task);

    fut.await;

    Ok(())
}

async fn steam_data_task(task: SteamDataTask) {
    if let Some(_) = task.game_entry.steam_data {
        return;
    }

    let mut entry = task.game_entry;

    info!("processing '{}'", entry.name);
    update_entry(&mut entry).await;

    for entry in &mut entry.expansions {
        info!("processing '{}'", entry.name);
        update_entry(entry).await;
    }
    for entry in &mut entry.dlcs {
        info!("processing '{}'", entry.name);
        update_entry(entry).await;
    }
    for entry in &mut entry.remakes {
        info!("processing '{}'", entry.name);
        update_entry(entry).await;
    }
    for entry in &mut entry.remasters {
        info!("processing '{}'", entry.name);
        update_entry(entry).await;
    }

    if let Err(e) = write_game_entry(&task.firestore, &entry) {
        error!("Failed to write {} to Firestore: {}", entry.name, e);
    }
}

struct SteamDataTask {
    game_entry: GameEntry,
    firestore: Arc<api::FirestoreApi>,
}

async fn update_entry(game_entry: &mut GameEntry) {
    let steam_appid = get_steam_appid(game_entry);
    match steam_appid {
        Some(steam_appid) => {
            let steam_data = get_steam_data(steam_appid).await;
            game_entry.steam_data = Some(steam_data);
        }
        None => warn!("missing steam entry for '{}'", game_entry.name),
    }
}

fn get_steam_appid(game_entry: &GameEntry) -> Option<u64> {
    game_entry
        .websites
        .iter()
        .find_map(|website| match website.authority {
            documents::WebsiteAuthority::Steam => website
                .url
                .split("/")
                .collect::<Vec<_>>()
                .iter()
                .rev()
                .find_map(|s| s.parse().ok()),
            _ => None,
        })
}

async fn get_steam_data(steam_appid: u64) -> SteamData {
    let steam_data = match SteamApi::get_app_details(steam_appid).await {
        Ok(steam_data) => steam_data,
        Err(e) => {
            error!("{}", e);
            return SteamData::default();
        }
    };
    steam_data
}

#[instrument(level = "trace", skip(firestore))]
pub fn read_game_entries(firestore: &api::FirestoreApi) -> Result<Vec<GameEntry>, Status> {
    match firestore.list::<GameEntry>(&format!("games_v2")) {
        Ok(entries) => Ok(entries),
        Err(e) => Err(Status::new("LibraryManager.read_game_entries: ", e)),
    }
}

#[instrument(level = "trace", skip(firestore, game_entry), fields(game = %game_entry.name))]
pub fn write_game_entry(
    firestore: &api::FirestoreApi,
    game_entry: &GameEntry,
) -> Result<(), Status> {
    match firestore.write("games_v2", Some(&game_entry.id.to_string()), game_entry) {
        Ok(_) => Ok(()),
        Err(e) => Err(Status::new("LibraryManager.write_game_entry: ", e)),
    }
}
