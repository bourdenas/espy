use prost::bytes::Bytes;
use prost::Message;
use std::fs;

/// Loads a proto message from file.
pub fn load<T: Message + Default>(
    path: &str,
) -> Result<T, Box<dyn std::error::Error + Send + Sync>> {
    let msg = Bytes::from(fs::read(path)?);
    Ok(T::decode(msg)?)
}

/// Saves a proto message to a file.
pub fn save<T: Message + Default>(
    path: &str,
    msg: &T,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let mut bytes = vec![];
    msg.encode(&mut bytes)?;
    fs::write(path, bytes)?;
    Ok(())
}

/// Saves a human readable representation of proto message to a file.
pub fn save_text<T: Message + Default>(
    path: &str,
    msg: &T,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let text = format!("{:#?}", msg);
    fs::write(path, text)?;
    Ok(())
}
