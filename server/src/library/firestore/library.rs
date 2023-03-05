use crate::{
    api::FirestoreApi,
    documents::{GameEntry, Library, LibraryEntry, StoreEntry},
    Status,
};
use tracing::instrument;

#[instrument(level = "trace", skip(firestore, user_id))]
pub fn read(firestore: &FirestoreApi, user_id: &str) -> Result<Library, Status> {
    match firestore.read(&format!("users/{user_id}/games"), "library") {
        Ok(library) => Ok(library),
        Err(Status::NotFound(_)) => Ok(Library::default()),
        Err(e) => Err(e),
    }
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
    skip(firestore, user_id),
    fields(
        entries_len = %entries.len(),
    ),
)]
pub fn add_entries(
    firestore: &FirestoreApi,
    user_id: &str,
    entries: Vec<(StoreEntry, u64, GameEntry)>,
) -> Result<(), Status> {
    let mut library = read(firestore, user_id)?;

    for (store_entry, owned_game_id, game_entry) in entries {
        let library_entry = LibraryEntry::new(game_entry, vec![store_entry], vec![owned_game_id]);
        add(library_entry, &mut library);
    }
    write(firestore, user_id, &library)?;

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
    if remove(store_entry, library_entry.id, &mut library) {
        write(firestore, user_id, &library)?;
    }
    Ok(())
}

#[instrument(level = "trace", skip(firestore, user_id))]
pub fn remove_storefront(
    firestore: &FirestoreApi,
    user_id: &str,
    storefront_id: &str,
) -> Result<(), Status> {
    let mut library = read(firestore, user_id)?;
    remove_store_entries(storefront_id, &mut library);
    write(firestore, user_id, &library)
}

/// Adds `LibraryEntry` in the library.
///
/// If an entry exists for the same game, it merges its store entries.
/// Returns true if the entry is added.
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

/// Removes a `StoreEntry` that is matched `game_id` from the `Library`.
///
/// If the associated LibraryEntry in the library the whole LibraryEntry is also
/// removed. Returns true if input `StoreEntry` was found.
fn remove(store_entry: &StoreEntry, game_id: u64, library: &mut Library) -> bool {
    let mut entry_found = false;
    library.entries.retain_mut(|e| {
        if e.id == game_id {
            e.store_entries.retain(|se| {
                let retain = se.storefront_name != store_entry.storefront_name
                    || se.id != store_entry.id
                    || se.title != store_entry.title;
                if !retain {
                    entry_found = true;
                }
                retain
            });

            return !e.store_entries.is_empty();
        }

        true
    });

    entry_found
}

/// Removes all entries in `Library` from a specified storefront.
fn remove_store_entries(storefront_id: &str, library: &mut Library) {
    library.entries.retain_mut(|library_entry| {
        library_entry
            .store_entries
            .retain(|store_entry| store_entry.storefront_name != storefront_id);

        return !library_entry.store_entries.is_empty();
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    fn library_entry(id: u64) -> LibraryEntry {
        LibraryEntry {
            id,
            store_entries: vec![StoreEntry {
                id: "store_id_0".to_owned(),
                title: "Game Title".to_owned(),
                storefront_name: "gog".to_owned(),
                ..Default::default()
            }],
            owned_versions: vec![id],
            ..Default::default()
        }
    }

    fn library_entry_with_stores(id: u64, stores: Vec<(&str, &str)>) -> LibraryEntry {
        LibraryEntry {
            id,
            store_entries: stores
                .iter()
                .map(|(store_game_id, store)| StoreEntry {
                    id: store_game_id.to_string(),
                    title: "Game Title".to_owned(),
                    storefront_name: store.to_string(),
                    ..Default::default()
                })
                .collect(),
            owned_versions: vec![id],
            ..Default::default()
        }
    }

    #[test]
    fn add_in_empty_library() {
        let mut library = Library { entries: vec![] };

        assert!(add(library_entry(7), &mut library));
        assert_eq!(library.entries.len(), 1);
    }

    #[test]
    fn add_same_library_entry() {
        let mut library = Library {
            entries: vec![library_entry(7)],
        };

        assert!(add(library_entry(7), &mut library));
        assert_eq!(library.entries.len(), 1);
        assert_eq!(library.entries[0].store_entries.len(), 2);
        assert_eq!(library.entries[0].owned_versions.len(), 2);
    }

    #[test]
    fn remove_non_existing_entry() {
        let mut library = Library { entries: vec![] };

        let library_entry = library_entry(7);
        assert_eq!(
            remove(
                &library_entry.store_entries[0],
                library_entry.id,
                &mut library,
            ),
            false
        );
        assert_eq!(library.entries.len(), 0);
    }

    #[test]
    fn remove_entry_with_single_store() {
        let mut library = Library {
            entries: vec![library_entry(7), library_entry(3)],
        };

        let library_entry = library_entry(7);
        assert!(remove(
            &library_entry.store_entries[0],
            library_entry.id,
            &mut library,
        ));
        assert_eq!(library.entries.len(), 1);
    }

    #[test]
    fn remove_entry_with_multiple_stores() {
        let mut library = Library {
            entries: vec![
                library_entry_with_stores(7, vec![("store_id_0", "gog"), ("steam id", "steam")]),
                library_entry(3),
            ],
        };

        let library_entry = library_entry(7);
        assert!(remove(
            &library_entry.store_entries[0],
            library_entry.id,
            &mut library,
        ));
        assert_eq!(library.entries.len(), 2);
        assert_eq!(library.entries[0].store_entries.len(), 1);
    }

    #[test]
    fn remove_found_library_entry_but_not_store_entry() {
        let mut library = Library {
            entries: vec![library_entry(7), library_entry(3)],
        };

        assert_eq!(
            remove(
                &StoreEntry {
                    id: "some id".to_owned(),
                    title: "Game Title".to_owned(),
                    storefront_name: "steam".to_owned(),
                    ..Default::default()
                },
                library.entries[0].id,
                &mut library,
            ),
            false
        );
        assert_eq!(library.entries.len(), 2);
        assert_eq!(library.entries[0].store_entries.len(), 1);
    }

    #[test]
    fn remove_all_storefront_entries() {
        let mut library = Library {
            entries: vec![
                library_entry_with_stores(7, vec![("gog_123", "gog")]),
                library_entry_with_stores(3, vec![("gog_213", "gog")]),
            ],
        };

        remove_store_entries("gog", &mut library);
        assert_eq!(library.entries.len(), 0);
    }

    #[test]
    fn remove_all_storefront_entries_store_does_not_exist() {
        let mut library = Library {
            entries: vec![
                library_entry_with_stores(7, vec![("gog_123", "gog")]),
                library_entry_with_stores(3, vec![("gog_213", "gog")]),
            ],
        };

        remove_store_entries("steam", &mut library);
        assert_eq!(library.entries.len(), 2);
    }

    #[test]
    fn remove_all_storefront_entries_does_not_affect_other_stores() {
        let mut library = Library {
            entries: vec![
                library_entry_with_stores(7, vec![("gog_123", "gog")]),
                library_entry_with_stores(2, vec![("steam_123", "steam")]),
                library_entry_with_stores(3, vec![("gog_213", "gog")]),
                library_entry_with_stores(5, vec![("steam_231", "steam")]),
            ],
        };

        remove_store_entries("gog", &mut library);
        assert_eq!(library.entries.len(), 2);
    }

    #[test]
    fn remove_all_storefront_entries_maintain_entry_with_other_store() {
        let mut library = Library {
            entries: vec![
                library_entry_with_stores(7, vec![("gog_123", "gog"), ("steam_321", "steam")]),
                library_entry_with_stores(2, vec![("steam_123", "steam")]),
                library_entry_with_stores(3, vec![("gog_213", "gog")]),
                library_entry_with_stores(5, vec![("steam_231", "steam")]),
            ],
        };

        remove_store_entries("gog", &mut library);
        assert_eq!(library.entries.len(), 3);
    }
}
