use encoding_rs::{GB18030, GBK, UTF_8};
use flate2::read::GzDecoder;
use std::io::Read;

/// 将响应字节解码为字符串
pub fn decode_bytes(raw: &[u8], charset: &str) -> Result<String, String> {
    let bytes = if raw.len() >= 2 && raw[0] == 0x1f && raw[1] == 0x8b {
        let mut decoder = GzDecoder::new(raw);
        let mut decompressed = Vec::new();
        decoder
            .read_to_end(&mut decompressed)
            .map_err(|e| format!("gzip 解压失败: {e}"))?;
        decompressed
    } else {
        raw.to_vec()
    };

    let upper = charset.to_uppercase();
    if upper == "UTF-8" || upper == "UTF8" {
        if let Ok(s) = std::str::from_utf8(&bytes) {
            return Ok(s.to_string());
        }
        for enc in [GBK, GB18030] {
            let (cow, _, _) = enc.decode(&bytes);
            if !cow.contains('\u{FFFD}') {
                return Ok(cow.into_owned());
            }
        }
        let (cow, _, _) = UTF_8.decode(&bytes);
        return Ok(cow.into_owned());
    }

    if upper.contains("GB") || upper == "936" || upper.contains("936") {
        for enc in [GBK, GB18030] {
            let (cow, _, _) = enc.decode(&bytes);
            return Ok(cow.into_owned());
        }
    }

    if let Ok(s) = std::str::from_utf8(&bytes) {
        return Ok(s.to_string());
    }
    let (cow, _, _) = UTF_8.decode(&bytes);
    Ok(cow.into_owned())
}

/// POST body 编码（GBK 场景）
pub fn encode_form_body(body: &str, charset: &str) -> String {
    let upper = charset.to_uppercase();
    if upper != "UTF-8" && upper != "UTF8" {
        body.split('&')
            .map(|pair| {
                if let Some((key, val)) = pair.split_once('=') {
                    let encoded = percent_encode_gbk(val);
                    format!("{key}={encoded}")
                } else {
                    pair.to_string()
                }
            })
            .collect::<Vec<_>>()
            .join("&")
    } else {
        body.split('&')
            .map(|pair| {
                if let Some((key, val)) = pair.split_once('=') {
                    format!("{key}={}", urlencoding_encode(val))
                } else {
                    pair.to_string()
                }
            })
            .collect::<Vec<_>>()
            .join("&")
    }
}

fn percent_encode_gbk(s: &str) -> String {
    let (encoded, _, _) = GBK.encode(s);
    encoded
        .iter()
        .map(|b| format!("%{b:02X}"))
        .collect::<String>()
}

fn urlencoding_encode(s: &str) -> String {
    s.chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || "-_.~".contains(c) {
                c.to_string()
            } else {
                let mut buf = [0u8; 4];
                let encoded = c.encode_utf8(&mut buf);
                encoded
                    .bytes()
                    .map(|b| format!("%{b:02X}"))
                    .collect::<String>()
            }
        })
        .collect::<String>()
}
