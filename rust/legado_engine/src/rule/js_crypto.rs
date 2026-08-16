//! Legado `java.createSymmetricCrypto` 后端（Hutool Cipher 兼容子集）
use aes::cipher::{block_padding::Pkcs7, BlockDecryptMut, BlockEncryptMut, KeyInit, KeyIvInit};
use base64::{engine::general_purpose::STANDARD as B64, Engine};

type Aes128CbcEnc = cbc::Encryptor<aes::Aes128>;
type Aes192CbcEnc = cbc::Encryptor<aes::Aes192>;
type Aes256CbcEnc = cbc::Encryptor<aes::Aes256>;
type Aes128CbcDec = cbc::Decryptor<aes::Aes128>;
type Aes192CbcDec = cbc::Decryptor<aes::Aes192>;
type Aes256CbcDec = cbc::Decryptor<aes::Aes256>;
type Aes128EcbEnc = ecb::Encryptor<aes::Aes128>;
type Aes192EcbEnc = ecb::Encryptor<aes::Aes192>;
type Aes256EcbEnc = ecb::Encryptor<aes::Aes256>;
type Aes128EcbDec = ecb::Decryptor<aes::Aes128>;
type Aes192EcbDec = ecb::Decryptor<aes::Aes192>;
type Aes256EcbDec = ecb::Decryptor<aes::Aes256>;

/// 解析 `AES/CBC/PKCS5Padding` 一类 transformation。
fn parse_transformation(t: &str) -> Result<(String, String), String> {
    let parts: Vec<&str> = t.split('/').collect();
    if parts.is_empty() {
        return Err("空 transformation".into());
    }
    let algo = parts[0].to_uppercase();
    if algo != "AES" {
        return Err(format!("暂不支持算法: {algo}"));
    }
    let mode = parts
        .get(1)
        .map(|s| s.to_uppercase())
        .unwrap_or_else(|| "CBC".into());
    Ok((algo, mode))
}

fn key_bytes(key: &str) -> Result<Vec<u8>, String> {
    let b = key.as_bytes();
    match b.len() {
        16 | 24 | 32 => Ok(b.to_vec()),
        n if n < 16 => {
            let mut out = b.to_vec();
            out.resize(16, 0);
            Ok(out)
        }
        n if n < 24 => {
            let mut out = b.to_vec();
            out.resize(24, 0);
            Ok(out)
        }
        n if n < 32 => {
            let mut out = b.to_vec();
            out.resize(32, 0);
            Ok(out)
        }
        _ => Ok(b[..32].to_vec()),
    }
}

fn iv_bytes(iv: &str, mode: &str) -> Result<Vec<u8>, String> {
    if mode == "ECB" {
        return Ok(vec![]);
    }
    let b = iv.as_bytes();
    if b.len() == 16 {
        return Ok(b.to_vec());
    }
    if b.len() > 16 {
        return Ok(b[..16].to_vec());
    }
    let mut out = b.to_vec();
    out.resize(16, 0);
    Ok(out)
}

/// AES 加密，返回标准 Base64（对齐 Hutool `encryptBase64`）
pub fn encrypt_base64(
    transformation: &str,
    key: &str,
    iv: &str,
    data: &str,
) -> Result<String, String> {
    let (_, mode) = parse_transformation(transformation)?;
    let key = key_bytes(key)?;
    let iv = iv_bytes(iv, &mode)?;
    let pt = data.as_bytes();
    let ct = match (mode.as_str(), key.len()) {
        ("CBC", 16) => {
            let mut buf = vec![0u8; pt.len() + 16];
            let n = Aes128CbcEnc::new_from_slices(&key, &iv)
                .map_err(|e| format!("AES init: {e}"))?
                .encrypt_padded_b2b_mut::<Pkcs7>(pt, &mut buf)
                .map_err(|e| format!("AES encrypt: {e}"))?
                .len();
            buf.truncate(n);
            buf
        }
        ("CBC", 24) => {
            let mut buf = vec![0u8; pt.len() + 16];
            let n = Aes192CbcEnc::new_from_slices(&key, &iv)
                .map_err(|e| format!("AES init: {e}"))?
                .encrypt_padded_b2b_mut::<Pkcs7>(pt, &mut buf)
                .map_err(|e| format!("AES encrypt: {e}"))?
                .len();
            buf.truncate(n);
            buf
        }
        ("CBC", 32) => {
            let mut buf = vec![0u8; pt.len() + 16];
            let n = Aes256CbcEnc::new_from_slices(&key, &iv)
                .map_err(|e| format!("AES init: {e}"))?
                .encrypt_padded_b2b_mut::<Pkcs7>(pt, &mut buf)
                .map_err(|e| format!("AES encrypt: {e}"))?
                .len();
            buf.truncate(n);
            buf
        }
        ("ECB", 16) => {
            let mut buf = vec![0u8; pt.len() + 16];
            buf[..pt.len()].copy_from_slice(pt);
            let n = Aes128EcbEnc::new_from_slice(&key)
                .map_err(|e| format!("AES init: {e}"))?
                .encrypt_padded_mut::<Pkcs7>(&mut buf, pt.len())
                .map_err(|e| format!("AES encrypt: {e}"))?
                .len();
            buf.truncate(n);
            buf
        }
        ("ECB", 24) => {
            let mut buf = vec![0u8; pt.len() + 16];
            buf[..pt.len()].copy_from_slice(pt);
            let n = Aes192EcbEnc::new_from_slice(&key)
                .map_err(|e| format!("AES init: {e}"))?
                .encrypt_padded_mut::<Pkcs7>(&mut buf, pt.len())
                .map_err(|e| format!("AES encrypt: {e}"))?
                .len();
            buf.truncate(n);
            buf
        }
        ("ECB", 32) => {
            let mut buf = vec![0u8; pt.len() + 16];
            buf[..pt.len()].copy_from_slice(pt);
            let n = Aes256EcbEnc::new_from_slice(&key)
                .map_err(|e| format!("AES init: {e}"))?
                .encrypt_padded_mut::<Pkcs7>(&mut buf, pt.len())
                .map_err(|e| format!("AES encrypt: {e}"))?
                .len();
            buf.truncate(n);
            buf
        }
        (m, k) => return Err(format!("不支持 AES/{m} keyLen={k}")),
    };
    Ok(B64.encode(ct))
}

/// AES 解密 Base64 → UTF-8 字符串（对齐 Hutool `decryptStr`）
pub fn decrypt_str(
    transformation: &str,
    key: &str,
    iv: &str,
    data_b64: &str,
) -> Result<String, String> {
    let (_, mode) = parse_transformation(transformation)?;
    let key = key_bytes(key)?;
    let iv = iv_bytes(iv, &mode)?;
    let mut ct = B64
        .decode(data_b64.trim())
        .map_err(|e| format!("Base64 解码失败: {e}"))?;
    let pt = match (mode.as_str(), key.len()) {
        ("CBC", 16) => Aes128CbcDec::new_from_slices(&key, &iv)
            .map_err(|e| format!("AES init: {e}"))?
            .decrypt_padded_mut::<Pkcs7>(&mut ct)
            .map_err(|e| format!("AES decrypt: {e}"))?
            .to_vec(),
        ("CBC", 24) => Aes192CbcDec::new_from_slices(&key, &iv)
            .map_err(|e| format!("AES init: {e}"))?
            .decrypt_padded_mut::<Pkcs7>(&mut ct)
            .map_err(|e| format!("AES decrypt: {e}"))?
            .to_vec(),
        ("CBC", 32) => Aes256CbcDec::new_from_slices(&key, &iv)
            .map_err(|e| format!("AES init: {e}"))?
            .decrypt_padded_mut::<Pkcs7>(&mut ct)
            .map_err(|e| format!("AES decrypt: {e}"))?
            .to_vec(),
        ("ECB", 16) => Aes128EcbDec::new_from_slice(&key)
            .map_err(|e| format!("AES init: {e}"))?
            .decrypt_padded_mut::<Pkcs7>(&mut ct)
            .map_err(|e| format!("AES decrypt: {e}"))?
            .to_vec(),
        ("ECB", 24) => Aes192EcbDec::new_from_slice(&key)
            .map_err(|e| format!("AES init: {e}"))?
            .decrypt_padded_mut::<Pkcs7>(&mut ct)
            .map_err(|e| format!("AES decrypt: {e}"))?
            .to_vec(),
        ("ECB", 32) => Aes256EcbDec::new_from_slice(&key)
            .map_err(|e| format!("AES init: {e}"))?
            .decrypt_padded_mut::<Pkcs7>(&mut ct)
            .map_err(|e| format!("AES decrypt: {e}"))?
            .to_vec(),
        (m, k) => return Err(format!("decrypt 暂不支持 AES/{m} keyLen={k}")),
    };
    String::from_utf8(pt).map_err(|e| format!("解密结果非 UTF-8: {e}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kele_encrypt_vector() {
        let mut key32 = String::from("lzxHpH8PLGXcrCIQ");
        while key32.len() < 32 {
            key32.push('\0');
        }
        let out =
            encrypt_base64("AES/CBC/PKCS5Padding", &key32, "lzxHpH8PLGXcrCIQ", "重生之").unwrap();
        assert_eq!(out, "breUSzu0dAfgrP33wtpsvg==");
    }

    #[test]
    fn roundtrip_cbc() {
        let key = "0123456789abcdef";
        let iv = "fedcba9876543210";
        let enc = encrypt_base64("AES/CBC/PKCS5Padding", key, iv, "hello").unwrap();
        let dec = decrypt_str("AES/CBC/PKCS5Padding", key, iv, &enc).unwrap();
        assert_eq!(dec, "hello");
    }

    #[test]
    fn roundtrip_ecb() {
        let key = "0123456789abcdef";
        let enc = encrypt_base64("AES/ECB/PKCS5Padding", key, "", "hello").unwrap();
        let dec = decrypt_str("AES/ECB/PKCS5Padding", key, "", &enc).unwrap();
        assert_eq!(dec, "hello");
    }
}
