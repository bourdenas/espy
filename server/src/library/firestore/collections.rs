use crate::{api::FirestoreApi, documents::IgdbCollection, Status};
use tracing::instrument;

/// Returns a list of all Collection docs stored on Firestore.
#[instrument(name = "collections::list", level = "trace", skip(firestore))]
pub fn list(firestore: &FirestoreApi) -> Result<Vec<IgdbCollection>, Status> {
    firestore.list(&format!("collections"))
}

/// Returns an IgdbCollection doc based on `collection_id` from Firestore.
#[instrument(name = "collections::read", level = "trace", skip(firestore))]
pub fn read(firestore: &FirestoreApi, collection_id: u64) -> Result<IgdbCollection, Status> {
    firestore.read::<IgdbCollection>("collections", &collection_id.to_string())
}

/// Writes an IgdbCollection doc in Firestore.
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

/// Deletes an IgdbCollection doc from Firestore.
#[instrument(name = "collections::delete", level = "trace", skip(firestore))]
pub fn delete(firestore: &FirestoreApi, collection_id: u64) -> Result<(), Status> {
    firestore.delete(&format!("collections/{}", collection_id.to_string()))
}
