use crate::{api::FirestoreApi, documents::GameEntry, Status};
use tracing::instrument;

/// Returns a list of all games stored on espy Firestore.
#[instrument(name = "games::list", level = "trace", skip(firestore))]
pub fn list(firestore: &FirestoreApi) -> Result<Vec<GameEntry>, Status> {
    firestore.list(&format!("games"))
}

/// Returns a GameEntry doc based on `game_id` from Firestore.
#[instrument(name = "games::read", level = "trace", skip(firestore))]
pub fn read(firestore: &FirestoreApi, game_id: u64) -> Result<GameEntry, Status> {
    firestore.read::<GameEntry>("games", &game_id.to_string())
}

/// Writes a GameEntry doc in Firestore.
#[instrument(name = "games::write", level = "trace", skip(firestore, game_entry))]
pub fn write(firestore: &FirestoreApi, game_entry: &GameEntry) -> Result<(), Status> {
    firestore.write("games", Some(&game_entry.id.to_string()), game_entry)?;
    Ok(())
}

/// Returns a GameEntry doc based on `game_id` from Firestore.
#[instrument(name = "games::delete", level = "trace", skip(firestore))]
pub fn delete(firestore: &FirestoreApi, game_id: u64) -> Result<(), Status> {
    firestore.delete(&format!("games/{}", game_id.to_string()))
}
