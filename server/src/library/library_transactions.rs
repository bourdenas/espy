use crate::{api::FirestoreApi, documents::StoreEntry, Status};
use std::collections::HashSet;
use tracing::instrument;

use super::firestore;

pub struct LibraryTransactions;

/// NOTE: All operations here should be transactions, but this is not currently
/// supported by this library.
///
/// NOTE: LibraryTransactions are, in general, not re-entrant. Executing Library
/// transactions on the same user in parallel is not deterministic and can cause
/// errors.
impl LibraryTransactions {
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
            firestore::storefront::read(firestore, user_id, storefront_name).into_iter(),
        );

        let mut store_entries = store_entries;
        store_entries.retain(|entry| !game_ids.contains(&entry.id));

        for entry in &store_entries {
            firestore::unmatched::write(firestore, user_id, entry)?;
        }

        game_ids.extend(store_entries.into_iter().map(|store_entry| store_entry.id));
        firestore::storefront::write(
            firestore,
            user_id,
            storefront_name,
            game_ids.into_iter().collect::<Vec<_>>(),
        )?;

        Ok(())
    }
}
