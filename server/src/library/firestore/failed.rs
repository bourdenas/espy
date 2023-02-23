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
        .retain(|e| e.id != store_entry.id || e.storefront_name != store_entry.storefront_name);

    failed.entries.len() != original_len
}

#[cfg(test)]
mod tests {
    use super::*;

    fn new_store_entry(id: &str, storefront: &str) -> StoreEntry {
        StoreEntry {
            id: id.to_owned(),
            title: "Game Title".to_owned(),
            storefront_name: storefront.to_owned(),
            ..Default::default()
        }
    }

    #[test]
    fn add_in_empty_library() {
        let mut failed = FailedEntries { entries: vec![] };

        assert_eq!(add(new_store_entry("123", "gog"), &mut failed), true);
        assert_eq!(failed.entries.len(), 1);
    }

    #[test]
    fn add_in_non_empty_library() {
        let mut failed = FailedEntries {
            entries: vec![new_store_entry("213", "gog")],
        };

        assert_eq!(add(new_store_entry("123", "gog"), &mut failed), true);
        assert_eq!(failed.entries.len(), 2);
    }

    #[test]
    fn add_same_entry_twice() {
        let mut failed = FailedEntries {
            entries: vec![new_store_entry("213", "gog")],
        };

        assert_eq!(add(new_store_entry("123", "gog"), &mut failed), true);
        assert_eq!(failed.entries.len(), 2);
        assert_eq!(add(new_store_entry("123", "gog"), &mut failed), false);
        assert_eq!(failed.entries.len(), 2);
    }

    #[test]
    fn add_same_id_different_store() {
        let mut failed = FailedEntries {
            entries: vec![new_store_entry("213", "gog")],
        };

        assert_eq!(add(new_store_entry("123", "gog"), &mut failed), true);
        assert_eq!(failed.entries.len(), 2);
        assert_eq!(add(new_store_entry("123", "steam"), &mut failed), true);
        assert_eq!(failed.entries.len(), 3);
    }

    #[test]
    fn remove_from_empty_library() {
        let mut failed = FailedEntries { entries: vec![] };

        assert_eq!(remove(&new_store_entry("123", "gog"), &mut failed), false);
        assert_eq!(failed.entries.len(), 0);
    }

    #[test]
    fn remove_from_non_empty_library_not_found() {
        let mut failed = FailedEntries {
            entries: vec![new_store_entry("213", "gog")],
        };

        assert_eq!(remove(&new_store_entry("123", "gog"), &mut failed), false);
        assert_eq!(failed.entries.len(), 1);
    }

    #[test]
    fn remove_from_library_found() {
        let mut failed = FailedEntries {
            entries: vec![new_store_entry("213", "gog"), new_store_entry("123", "gog")],
        };

        assert_eq!(remove(&new_store_entry("123", "gog"), &mut failed), true);
        assert_eq!(failed.entries.len(), 1);
    }

    #[test]
    fn remove_from_library_same_id_different_store_exists() {
        let mut failed = FailedEntries {
            entries: vec![new_store_entry("213", "gog"), new_store_entry("123", "gog")],
        };

        assert_eq!(remove(&new_store_entry("123", "steam"), &mut failed), false);
        assert_eq!(failed.entries.len(), 2);
    }
}
