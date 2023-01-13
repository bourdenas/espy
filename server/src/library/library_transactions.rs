use super::library_ops::LibraryOps;
use crate::{
    api::FirestoreApi,
    documents::{GameEntry, Library, LibraryEntry, StoreEntry},
    Status,
};
use std::collections::HashSet;
use tracing::instrument;

pub struct LibraryTransactions;

/// NOTE: All operations here should be transactions, but this is not currently
/// supported by this library.
///
/// NOTE: LibraryTransactions are, in general, not re-entrant. Executing Library
/// transactions on the same user in parallel is not deterministic and can cause
/// errors.
impl LibraryTransactions {
    /// Handles successfully resovled StoreEntry.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn match_game(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: StoreEntry,
        owned_version: u64,
        game_entry: GameEntry,
    ) -> Result<(), Status> {
        LibraryOps::delete_unmatched(firestore, user_id, &store_entry)?;
        LibraryOps::delete_failed(firestore, user_id, &store_entry)?;
        Self::remove_from_wishlist(firestore, user_id, game_entry.id)?;

        add_library_entry(
            firestore,
            user_id,
            LibraryEntry::new(game_entry, vec![store_entry], vec![owned_version]),
        )?;

        Ok(())
    }

    /// Delete or unmatches (based on `delete`) a StoreEntry from the library.
    #[instrument(level = "trace", skip(firestore, user_id, operation))]
    pub fn unmatch_game(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
        library_entry: &LibraryEntry,
        operation: Op,
    ) -> Result<(), Status> {
        remove_library_entry(firestore, user_id, &store_entry, &library_entry)?;

        match operation {
            Op::Unmatch => (),
            Op::Failed => LibraryOps::write_failed(firestore, user_id, &store_entry)?,
            Op::Delete => LibraryOps::remove_from_storefront_ids(firestore, user_id, &store_entry)?,
        };

        Ok(())
    }

    /// Handles failed to resolve StoreEntry.
    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn match_failed(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
    ) -> Result<(), Status> {
        LibraryOps::delete_unmatched(firestore, user_id, store_entry)?;
        LibraryOps::write_failed(firestore, user_id, store_entry)?;

        Ok(())
    }

    #[instrument(
        level = "trace",
        skip(firestore, user_id, library_entry),
        fields(game_id = %library_entry.id),
    )]
    pub fn add_to_wishlist(
        firestore: &FirestoreApi,
        user_id: &str,
        library_entry: LibraryEntry,
    ) -> Result<(), Status> {
        let mut wishlist = match LibraryOps::read_wishlist(firestore, user_id) {
            Ok(wishlist) => wishlist,
            Err(_) => Library { entries: vec![] },
        };
        wishlist.entries.push(library_entry);
        LibraryOps::write_wishlist(firestore, user_id, &wishlist)
    }

    #[instrument(level = "trace", skip(firestore, user_id))]
    pub fn remove_from_wishlist(
        firestore: &FirestoreApi,
        user_id: &str,
        game_id: u64,
    ) -> Result<(), Status> {
        let mut wishlist = LibraryOps::read_wishlist(firestore, user_id)?;
        let original_len = wishlist.entries.len();
        wishlist.entries.retain(|entry| entry.id != game_id);
        if wishlist.entries.len() != original_len {
            return LibraryOps::write_wishlist(firestore, user_id, &wishlist);
        }
        Ok(())
    }

    /// Given store entries a remote storefront it updates user's library in
    /// Firestore.
    ///
    /// This operation updates
    /// (a) the `users/{user}/storefronts/{storefront_name}` document to contain all
    ///     storefront game ids owned by the user.
    /// (b) the `users/{user}/unmatched` collection with 'StoreEntry` documents that
    ///     correspond to new found entries.
    #[instrument(
        level = "trace",
        skip(firestore, user_id, store_entries),
        fields(entries = %store_entries.len()),
    )]
    pub fn store_new_to_unmatched(
        firestore: &FirestoreApi,
        user_id: &str,
        storefront_name: &str,
        store_entries: Vec<StoreEntry>,
    ) -> Result<(), Status> {
        let mut game_ids = HashSet::<String>::from_iter(
            LibraryOps::read_storefront_ids(firestore, user_id, storefront_name).into_iter(),
        );

        let mut store_entries = store_entries;
        store_entries.retain(|entry| !game_ids.contains(&entry.id));

        for entry in &store_entries {
            LibraryOps::write_unmatched(firestore, user_id, entry)?;
        }

        game_ids.extend(store_entries.into_iter().map(|store_entry| store_entry.id));
        LibraryOps::write_storefront_ids(
            firestore,
            user_id,
            storefront_name,
            game_ids.into_iter().collect::<Vec<_>>(),
        )?;

        Ok(())
    }
}

pub enum Op {
    Unmatch,
    Failed,
    Delete,
}

#[instrument(level = "trace", skip(firestore, user_id))]
fn add_library_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    library_entry: LibraryEntry,
) -> Result<(), Status> {
    let mut library = LibraryOps::read_library(firestore, user_id)?;

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

    LibraryOps::write_library(firestore, user_id, &library)
}

#[instrument(level = "trace", skip(firestore, user_id))]
fn remove_library_entry(
    firestore: &FirestoreApi,
    user_id: &str,
    store_entry: &StoreEntry,
    library_entry: &LibraryEntry,
) -> Result<(), Status> {
    let mut library = LibraryOps::read_library(firestore, user_id)?;

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

    LibraryOps::write_library(firestore, user_id, &library)
}
