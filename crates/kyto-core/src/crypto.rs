use std::fs;
use std::path::Path;

use chacha20poly1305::aead::{Aead, KeyInit};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use rand::RngCore;

use crate::error::{KytoError, KytoResult};

const MAGIC: &[u8; 4] = b"KYTO";
const NONCE_LEN: usize = 12;

pub fn load_key() -> KytoResult<[u8; 32]> {
    if let Ok(hex_key) = std::env::var("KYTO_KEY") {
        return decode_key_hex(&hex_key);
    }
    if let Some(home) = dirs_key_path() {
        if home.exists() {
            let raw = fs::read_to_string(&home)
                .map_err(|e| KytoError::Crypto(format!("read key file: {e}")))?;
            return decode_key_hex(raw.trim());
        }
    }
    Err(KytoError::Crypto(
        "missing KYTO_KEY or ~/.config/kyto/key (64 hex chars)".into(),
    ))
}

fn dirs_key_path() -> Option<std::path::PathBuf> {
    if let Ok(home) = std::env::var("USERPROFILE") {
        return Some(std::path::PathBuf::from(home).join(".config").join("kyto").join("key"));
    }
    if let Ok(home) = std::env::var("HOME") {
        return Some(std::path::PathBuf::from(home).join(".config").join("kyto").join("key"));
    }
    None
}

fn decode_key_hex(hex: &str) -> KytoResult<[u8; 32]> {
    let bytes = hex::decode(hex).map_err(|e| KytoError::Crypto(format!("invalid KYTO_KEY hex: {e}")))?;
    if bytes.len() != 32 {
        return Err(KytoError::Crypto("KYTO_KEY must be 32 bytes (64 hex chars)".into()));
    }
    let mut key = [0u8; 32];
    key.copy_from_slice(&bytes);
    Ok(key)
}

pub fn encrypt_file(input: &Path, output: &Path) -> KytoResult<()> {
    let plain = fs::read(input).map_err(|e| KytoError::Io(input.display().to_string(), e.to_string()))?;
    let key = load_key()?;
    let cipher = ChaCha20Poly1305::new_from_slice(&key)
        .map_err(|e| KytoError::Crypto(e.to_string()))?;
    let mut nonce_bytes = [0u8; NONCE_LEN];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    let ciphertext = cipher
        .encrypt(nonce, plain.as_ref())
        .map_err(|e| KytoError::Crypto(e.to_string()))?;
    let mut out = Vec::new();
    out.extend_from_slice(MAGIC);
    out.extend_from_slice(&nonce_bytes);
    out.extend_from_slice(&ciphertext);
    fs::write(output, out).map_err(|e| KytoError::Io(output.display().to_string(), e.to_string()))
}

pub fn decrypt_file(input: &Path) -> KytoResult<String> {
    let data = fs::read(input).map_err(|e| KytoError::Io(input.display().to_string(), e.to_string()))?;
    if data.len() < MAGIC.len() + NONCE_LEN + 16 {
        return Err(KytoError::Crypto("encrypted file too short".into()));
    }
    if &data[..4] != MAGIC {
        return Err(KytoError::Crypto("invalid Kyto encrypted file magic".into()));
    }
    let key = load_key()?;
    let cipher = ChaCha20Poly1305::new_from_slice(&key)
        .map_err(|e| KytoError::Crypto(e.to_string()))?;
    let nonce = Nonce::from_slice(&data[4..4 + NONCE_LEN]);
    let plain = cipher
        .decrypt(nonce, &data[4 + NONCE_LEN..])
        .map_err(|e| KytoError::Crypto(format!("decrypt failed: {e}")))?;
    String::from_utf8(plain).map_err(|e| KytoError::Crypto(format!("utf8: {e}")))
}
