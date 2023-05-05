use crate::{
    api::FirestoreApi,
    documents::{GameEntry, IgdbCollection},
    Status,
};
use tracing::instrument;

/// Returns a GameEntry doc based on `game_id` from Firestore.
#[instrument(name = "collections::read", level = "trace", skip(firestore))]
pub fn read(firestore: &FirestoreApi, collection_id: u64) -> Result<GameEntry, Status> {
    firestore.read::<GameEntry>("collections", &collection_id.to_string())
}

/// Writes a GameEntry doc in Firestore.
#[instrument(
    name = "collections::write",
    level = "trace",
    skip(firestore, collection)
    fields(
        collection = %collection.slug,
    )
)]
pub fn write(firestore: &FirestoreApi, collection: &IgdbCollection) -> Result<(), Status> {
    firestore.write("collections", Some(&collection.id.to_string()), collection)?;
    Ok(())
}

/// Returns a GameEntry doc based on `game_id` from Firestore.
#[instrument(name = "collections::delete", level = "trace", skip(firestore))]
pub fn delete(firestore: &FirestoreApi, collection_id: u64) -> Result<(), Status> {
    firestore.delete(&format!("collections/{}", collection_id.to_string()))
}
