use firestore_db_and_auth as firestore;
use firestore_db_and_auth::{Credentials, ServiceSession};

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
}
