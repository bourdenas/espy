use crate::{api::FirestoreApi, documents::ExternalGame, Status};
use tracing::instrument;

/// Returns a ExternalGame doc based on `store` and `store_id` from Firestore.
#[instrument(name = "external_games::read", level = "trace", skip(firestore))]
pub fn read(firestore: &FirestoreApi, store: &str, store_id: &str) -> Result<ExternalGame, Status> {
    firestore.read::<ExternalGame>("external_games", &format!("{}_{}", store, &store_id))
}

/// Writes a ExternalGame doc in Firestore.
#[instrument(
    name = "external_games::write",
    level = "trace",
    skip(firestore, external_game)
    fields(
        store_id = %external_game.store_id,
    )
)]
pub fn write(
    firestore: &FirestoreApi,
    store: &str,
    external_game: &ExternalGame,
) -> Result<(), Status> {
    firestore.write(
        "external_games",
        Some(&format!("{}_{}", store, &external_game.store_id)),
        external_game,
    )?;
    Ok(())
}

/// Returns a ExternalGame doc based on `store_id` from Firestore.
#[instrument(name = "external_games::delete", level = "trace", skip(firestore))]
pub fn delete(firestore: &FirestoreApi, store: &str, store_id: u64) -> Result<(), Status> {
    firestore.delete(&format!(
        "external_games/{}",
        &format!("{}_{}", store, &store_id)
    ))
}
