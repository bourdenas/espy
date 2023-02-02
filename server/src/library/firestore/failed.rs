use crate::{
    api::FirestoreApi,
    documents::{FailedEntries, StoreEntry},
    Status,
};
use tracing::instrument;

#[instrument(level = "trace", skip(firestore, user_id))]
pub fn read(firestore: &FirestoreApi, user_id: &str) -> Result<FailedEntries, Status> {
    firestore.read(&format!("users/{user_id}/games"), "failed")
}

#[instrument(level = "trace", skip(firestore, user_id, failed))]
pub fn write(
    firestore: &FirestoreApi,
    user_id: &str,
    failed: &FailedEntries,
) -> Result<(), Status> {
    firestore.write(&format!("users/{user_id}/games"), Some("failed"), failed)?;
    Ok(())
}

#[instrument(
    level = "trace",
    skip(firestore, user_id, store_entry),
    fields(store_entry_id = %store_entry.id),
)]
pub fn add_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: StoreEntry,
) -> Result<(), Status> {
    let mut failed = match read(firestore, user_id) {
        Ok(failed) => failed,
        Err(_) => FailedEntries { entries: vec![] },
    };

    if add(store_entry, &mut failed) {
        write(firestore, user_id, &failed)?;
    }
    Ok(())
}

#[instrument(
    level = "trace",
    skip(firestore, user_id, store_entry),
    fields(store_entry_id = %store_entry.id),
)]
pub fn remove_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
) -> Result<(), Status> {
    let mut failed = read(firestore, user_id)?;
    if remove(store_entry, &mut failed) {
        return write(firestore, user_id, &failed);
    }
    Ok(())
}

/// Adds `StoreEntry` in the failed to match entries.
///
/// Returns false if the same `StoreEntry` was already found, true otherwise.
fn add(store_entry: StoreEntry, failed: &mut FailedEntries) -> bool {
    match failed
        .entries
        .iter()
        .find(|e| e.id == store_entry.id && e.storefront_name == store_entry.storefront_name)
    {
        Some(_) => false,
        None => {
            failed.entries.push(store_entry);
            true
        }
    }
}

/// Remove `StoreEntry` from the failed to match entries.
///
/// Returns true if the `StoreEntry` was found and removed, false otherwise.
fn remove(store_entry: &StoreEntry, failed: &mut FailedEntries) -> bool {
    let original_len = failed.entries.len();
    failed
        .entries
        .retain(|e| e.id != store_entry.id && e.storefront_name != store_entry.storefront_name);

    failed.entries.len() != original_len
}