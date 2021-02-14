use prost::bytes::Bytes;
use prost::Message;
use std::fs;

/// Loads a proto message from file.
pub fn load<T: Message + Default>(path: &str) -> Result<T, Box<dyn std::error::Error>> {
    let msg = Bytes::from(fs::read(path)?);
    Ok(T::decode(msg)?)
}
