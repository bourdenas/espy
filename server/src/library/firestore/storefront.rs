use crate::{api::FirestoreApi, documents::StoreEntry, documents::Storefront, Status};
use std::collections::{HashMap, HashSet};
use tracing::instrument;

/// Returns all store game ids owned by user from specified storefront.
///
/// Reads `users/{user}/storefronts/{storefront_name}` document in Firestore.
#[instrument(name = "storefront::read", level = "trace", skip(firestore, user_id))]
pub fn read(
    firestore: &FirestoreApi,
    user_id: &str,
    storefront: &str,
) -> Result<Vec<String>, Status> {
    match firestore.read::<Storefront>(&format!("users/{user_id}/storefronts"), storefront) {
        Ok(storefront) => Ok(storefront.owned_games),
        Err(Status::NotFound(_)) => Ok(vec![]),
        Err(e) => Err(e),
    }
}

/// Writes all store game ids owned by user from specified storefront.
///
/// Writes `users/{user}/storefronts/{storefront_name}` document in
/// Firestore.
#[instrument(
    name = "storefront::write",
    level = "trace",
    skip(firestore, user_id, owned_games)
)]
pub fn write(
    firestore: &FirestoreApi,
    user_id: &str,
    storefront: &str,
    owned_games: Vec<String>,
) -> Result<(), Status> {
    match firestore.write(
        &format!("users/{user_id}/storefronts"),
        Some(storefront),
        &Storefront {
            name: storefront.to_owned(),
            owned_games,
        },
    ) {
        Ok(_) => Ok(()),
        Err(e) => Err(Status::new("LibraryManager.write_storefront_ids: ", e)),
    }
}

/// Deletes a storefront record from user's library.
///
/// Deletes `users/{user}/storefronts/{storefront}` document in Firestore.
#[instrument(name = "storefront::delete", level = "trace", skip(firestore, user_id))]
pub fn delete(firestore: &FirestoreApi, user_id: &str, storefront: &str) -> Result<(), Status> {
    firestore.delete(&format!("users/{user_id}/storefronts/{storefront}"))
}

/// Returns input StoreEntries that are not already contained in user's
/// Storefront document.
///
/// Reads `users/{user}/storefronts/{storefront_name}` document in Firestore.
#[instrument(
    name = "storefront::diff_entries",
    level = "trace",
    skip(firestore, user_id)
)]
pub fn diff_entries(
    firestore: &FirestoreApi,
    user_id: &str,
    mut store_entries: Vec<StoreEntry>,
) -> Result<Vec<StoreEntry>, Status> {
    let storefront_name = match store_entries.first() {
        Some(entry) => &entry.storefront_name,
        None => return Ok(vec![]),
    };

    let game_ids =
        HashSet::<String>::from_iter(read(firestore, user_id, storefront_name)?.into_iter());
    store_entries.retain(|entry| !game_ids.contains(&entry.id));

    Ok(store_entries)
}

/// Add StoreEntry ids to the user's Storefront document.
///
/// Reads/writes `users/{user}/storefronts/{storefront_name}` document in
/// Firestore.
#[instrument(
    name = "storefront::add_entries",
    level = "trace",
    skip(firestore, user_id)
)]
pub fn add_entries(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entries: Vec<StoreEntry>,
) -> Result<(), Status> {
    for (name, store_entries) in group_by(store_entries) {
        let mut owned_entries = read(firestore, user_id, &name)?;
        for entry in &store_entries {
            owned_entries.push(entry.id.to_owned());
        }

        write(firestore, user_id, &name, owned_entries)?
    }

    Ok(())
}

/// Groups StoreEntries by storefront name.
fn group_by(store_entries: Vec<StoreEntry>) -> HashMap<String, Vec<StoreEntry>> {
    let mut groups = HashMap::<String, Vec<StoreEntry>>::new();

    for entry in store_entries {
        match groups.get_mut(&entry.storefront_name) {
            Some(entries) => entries.push(entry),
            None => {
                groups.insert(entry.storefront_name.to_owned(), vec![entry]);
            }
        }
    }

    groups
}

/// Add StoreEntry id to the user's Storefront document.
///
/// Reads/writes `users/{user}/storefronts/{storefront_name}` document in
/// Firestore.
#[instrument(
    name = "storefront::add_entry",
    level = "trace",
    skip(firestore, user_id)
)]
pub fn add_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: StoreEntry,
) -> Result<(), Status> {
    let mut owned_entries = read(firestore, user_id, &store_entry.storefront_name)?;
    owned_entries.push(store_entry.id.to_owned());

    write(
        firestore,
        user_id,
        &store_entry.storefront_name,
        owned_entries,
    )
}
/// Remove a StoreEntry from its Storefront.
///
/// Reads/writes `users/{user}/storefronts/{storefront_name}` document in
/// Firestore.
#[instrument(name = "storefront::remove", level = "trace", skip(firestore, user_id))]
pub fn remove(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
) -> Result<(), Status> {
    let mut owned_entries = read(firestore, user_id, &store_entry.storefront_name)?;
    owned_entries.retain(|id| *id != store_entry.id);

    write(
        firestore,
        user_id,
        &store_entry.storefront_name,
        owned_entries,
    )
}
