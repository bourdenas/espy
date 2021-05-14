use crate::Status;
use prost::bytes::Bytes;
use prost::Message;
use std::fs;

/// Loads a proto message from file.
pub fn load<T: Message + Default>(path: &str) -> Result<T, Status> {
    let msg = Bytes::from(fs::read(path)?);
    match T::decode(msg) {
        Ok(msg) => Ok(msg),
        Err(err) => Err(Status::new(format!("Failed to decode message: '{}'", err))),
    }
}

/// Saves a proto message to a file.
pub fn save<T: Message + Default>(path: &str, msg: &T) -> Result<(), Status> {
    let mut bytes = vec![];
    if let Err(err) = msg.encode(&mut bytes) {
        return Err(Status::new(format!(
            "Failed to encode message: {:?}\nwith error: {}",
            msg, err
        )));
    }

    fs::write(path, bytes)?;
    Ok(())
}

/// Saves a human readable representation of proto message to a file.
pub fn save_text<T: Message + Default>(path: &str, msg: &T) -> Result<(), Status> {
    let text = format!("{:#?}", msg);
    fs::write(path, text)?;
    Ok(())
}
