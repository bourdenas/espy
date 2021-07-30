use crate::Status;
use firestore_db_and_auth as firestore;
use firestore_db_and_auth::{documents, Credentials, ServiceSession};
use serde::{Deserialize, Serialize};

pub struct FirestoreApi {
    session: ServiceSession,
}

impl FirestoreApi {
    /// Returns a Firestore session created from input credentials.
    pub fn from_credentials(
        credentials_file: &str,
    ) -> Result<Self, firestore::errors::FirebaseError> {
        let mut cred = Credentials::from_file(credentials_file).expect("Read credentials file");
        cred.download_google_jwks()
            .expect("Failed to download public keys");

        Ok(FirestoreApi {
            session: ServiceSession::new(cred).expect("Create a service account session"),
        })
    }

    /// Returns a document based on its id.
    pub fn read<T>(&self, path: &str, doc_id: &str) -> Result<T, Status>
    where
        for<'a> T: Deserialize<'a>,
    {
        match documents::read(&self.session, path, doc_id) {
            Ok(doc) => Ok(doc),
            Err(_) => Err(Status::not_found(&format!(
                "Firebase document {}/{} not found.",
                path, doc_id
            ))),
        }
    }

    /// Writes or updates a document given an optional id. If None is provided
    /// for doc_id a new document is created with a generated id.
    /// Returns the document id.
    pub fn write<T>(&self, path: &str, doc_id: Option<&str>, doc: &T) -> Result<String, Status>
    where
        T: Serialize,
    {
        match documents::write(
            &self.session,
            path,
            doc_id,
            doc,
            documents::WriteOptions::default(),
        ) {
            Ok(result) => Ok(result.document_id),
            Err(e) => Err(Status::internal("Firestore.write: ", e)),
        }
    }
}
