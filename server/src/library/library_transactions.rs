use super::library_ops::LibraryOps;
use crate::{
    api::FirestoreApi,
    documents::{GameEntry, LibraryEntry, StoreEntry},
    Status,
};
use std::collections::HashSet;
use tracing::instrument;

pub struct LibraryTransactions;

/// NOTE: All operations here should be transactions, but this is not currently
/// supported by this library.
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

        let library_entry =
            LibraryEntry::new(game_entry, vec![store_entry.clone()], vec![owned_version]);

        LibraryOps::append_to_recent(firestore, user_id, library_entry.id, store_entry)?;

        // Update LibraryEntry. It might already exist from a different
        // storefront.
        LibraryOps::update_library_entry(firestore, user_id, library_entry)?;

        Ok(())
    }

    /// Delete or unmatches (based on `delete`) a StoreEntry from the library.
    #[instrument(level = "trace", skip(firestore, user_id, operation))]
    pub fn unmatch_game(
        firestore: &FirestoreApi,
        user_id: &str,
        store_entry: &StoreEntry,
        library_entry: LibraryEntry,
        operation: Op,
    ) -> Result<(), Status> {
        let mut library_entry = library_entry;
        LibraryOps::remove_from_library_entry(
            firestore,
            user_id,
            &store_entry,
            &mut library_entry,
        )?;

        LibraryOps::remove_from_recent(firestore, user_id, &store_entry)?;

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

    /// Given store entries a remote storefront it updates user's library in
    /// Firestore.
    ///
    /// This operation updates
    /// (a) the `users/{user}/storefronts/{storefront_name}` document to contain all
    ///     storefront game ids owned by the user.
    /// (b) the `users/{user}/unmatched` collection with 'StoreEntry` documents that
    ///     correspond to new found entries.
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
