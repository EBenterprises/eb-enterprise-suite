use openssl::symm::{encrypt, decrypt, Cipher};

pub fn encrypt_payload(key: &[u8], iv: &[u8], plaintext: &[u8]) -> Result<String, openssl::error::ErrorStack> {
    let cipher = Cipher::aes_256_cbc();
    let ciphertext = encrypt(cipher, key, Some(iv), plaintext)?;
    Ok(hex::encode(ciphertext))
}

pub fn decrypt_payload(key: &[u8], iv: &[u8], ciphertext_hex: &str) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let cipher = Cipher::aes_256_cbc();
    let ciphertext = hex::decode(ciphertext_hex)?;
    let plaintext = decrypt(cipher, key, Some(iv), &ciphertext)?;
    Ok(plaintext)
}
