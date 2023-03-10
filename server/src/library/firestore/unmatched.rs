use crate::{api::FirestoreApi, documents::StoreEntry, Status};
use tracing::instrument;

/// Returns StoreEntries from the unmatched collection in user's kibrary.
///
/// Reads `StoreEntry` documents under collection `users/{user}/unmatched`
/// in Firestore.
#[instrument(name = "unmatched::list", level = "trace", skip(firestore, user_id))]
pub fn list(firestore: &FirestoreApi, user_id: &str) -> Result<Vec<StoreEntry>, Status> {
    firestore.list::<StoreEntry>(&format!("users/{user_id}/unmatched"))
}

/// Store store entry to user's unmatched collection.
///
/// Writes `StoreEntry` documents under collection `users/{user}/unmatched`
/// in Firestore.
#[instrument(name = "unmatched::write", level = "trace", skip(firestore, user_id))]
pub fn write(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
) -> Result<(), Status> {
    let mut title = String::default();
    if store_entry.id.is_empty() {
        title = safe_title(store_entry);
    }

    firestore.write(
        &format!("users/{user_id}/unmatched"),
        Some(&format!(
            "{}_{}",
            &store_entry.storefront_name,
            match store_entry.id.is_empty() {
                false => &store_entry.id,
                true => &title,
            },
        )),
        store_entry,
    )?;

    Ok(())
}

/// Deletes store entry from user's unmatched collection.
///
/// Deletes `StoreEntry` documents under collection `users/{user}/unmatched`
/// in Firestore.
#[instrument(name = "unmatched::delete", level = "trace", skip(firestore, user_id))]
pub fn delete(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
) -> Result<(), Status> {
    let mut title = String::default();
    if store_entry.id.is_empty() {
        title = safe_title(store_entry);
    }

    firestore.delete(&format!(
        "users/{user_id}/unmatched/{}_{}",
        &store_entry.storefront_name,
        match store_entry.id.is_empty() {
            false => &store_entry.id,
            true => &title,
        },
    ))?;

    Ok(())
}

fn safe_title(store_entry: &StoreEntry) -> String {
    store_entry
        .title
        .replace(|c: char| !c.is_alphanumeric(), "_")
}
