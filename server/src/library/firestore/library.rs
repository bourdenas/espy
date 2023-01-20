use crate::{
    api::FirestoreApi,
    documents::{GameEntry, Library, LibraryEntry, StoreEntry},
    Status,
};
use tracing::instrument;

#[instrument(level = "trace", skip(firestore, user_id))]
pub fn read(firestore: &FirestoreApi, user_id: &str) -> Result<Library, Status> {
    firestore.read(&format!("users/{user_id}/games"), "library")
}

#[instrument(level = "trace", skip(firestore, user_id, library))]
pub fn write(firestore: &FirestoreApi, user_id: &str, library: &Library) -> Result<(), Status> {
    firestore.write(&format!("users/{user_id}/games"), Some(&"library"), library)?;
    Ok(())
}

#[instrument(
    level = "trace",
    skip(firestore, user_id, game_entry),
    fields(
        game_id = %game_entry.id,
    ),
)]
pub fn add_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: StoreEntry,
    owned_version: u64,
    game_entry: GameEntry,
) -> Result<(), Status> {
    let library_entry = LibraryEntry::new(game_entry, vec![store_entry], vec![owned_version]);
    let mut library = read(firestore, user_id)?;
    if add(library_entry, &mut library) {
        write(firestore, user_id, &library)?;
    }
    Ok(())
}

#[instrument(
    level = "trace",
    skip(firestore, user_id, library_entry),
    fields(
        game_id = %library_entry.id,
    ),
)]
pub fn remove_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
    library_entry: &LibraryEntry,
) -> Result<(), Status> {
    let mut library = read(firestore, user_id)?;
    if remove(store_entry, library_entry, &mut library) {
        write(firestore, user_id, &library)?;
    }
    Ok(())
}

fn add(library_entry: LibraryEntry, library: &mut Library) -> bool {
    match library
        .entries
        .iter_mut()
        .find(|e| e.id == library_entry.id)
    {
        Some(existing_entry) => {
            existing_entry
                .store_entries
                .extend(library_entry.store_entries.into_iter());
            existing_entry
                .owned_versions
                .extend(library_entry.owned_versions.into_iter());
        }
        None => library.entries.push(library_entry),
    }

    true
}

fn remove(store_entry: &StoreEntry, library_entry: &LibraryEntry, library: &mut Library) -> bool {
    let original_len = library.entries.len();
    library.entries.retain_mut(|e| {
        if e.id != library_entry.id {
            e.store_entries.retain(|se| {
                se.storefront_name != store_entry.storefront_name
                    || se.id != store_entry.id
                    || se.title != store_entry.title
            });

            return !library_entry.store_entries.is_empty();
        }

        true
    });

    library.entries.len() != original_len
}
