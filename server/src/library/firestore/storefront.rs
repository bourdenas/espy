use crate::{api::FirestoreApi, documents::StoreEntry, documents::Storefront, Status};
use tracing::instrument;

/// Returns all store game ids owned by user from specified storefront.
///
/// Reads `users/{user}/storefront/{storefront_name}` document in Firestore.
#[instrument(level = "trace", skip(firestore, user_id))]
pub fn read(firestore: &FirestoreApi, user_id: &str, storefront: &str) -> Vec<String> {
    match firestore.read::<Storefront>(&format!("users/{user_id}/storefronts"), storefront) {
        Ok(storefront) => storefront.owned_games,
        Err(_) => vec![],
    }
}

/// Writes all store game ids owned by user from specified storefront.
///
/// Writes `users/{user}/storefront/{storefront_name}` document in
/// Firestore.
#[instrument(level = "trace", skip(firestore, user_id, owned_games))]
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
/// Deletes `users/{user}/storefront/{storefront}` document in Firestore.
#[instrument(level = "trace", skip(firestore, user_id))]
pub fn delete(firestore: &FirestoreApi, user_id: &str, storefront: &str) -> Result<(), Status> {
    firestore.delete(&format!("users/{user_id}/storefronts/{storefront}"))
}

/// Remove a StoreEntry from its Storefront.
///
/// Reads/writes `users/{user}/storefront/{storefront_name}` document in
/// Firestore.
#[instrument(level = "trace", skip(firestore, user_id))]
pub fn remove(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
) -> Result<(), Status> {
    let mut storefront = match firestore.read::<Storefront>(
        &format!("users/{user_id}/storefront"),
        &store_entry.storefront_name,
    ) {
        Ok(storefront) => storefront,
        Err(_) => Storefront {
            name: store_entry.storefront_name.clone(),
            ..Default::default()
        },
    };

    let index = storefront
        .owned_games
        .iter()
        .position(|id| *id == store_entry.id);

    if let Some(index) = index {
        storefront.owned_games.remove(index);
        firestore.write(
            &format!("users/{user_id}/storefront"),
            Some(&store_entry.storefront_name),
            &storefront,
        )?;
    }

    Ok(())
}
