//! 跨 QuickJS Runtime 的书源 `cache`（对齐 Jingshiro AppCache）
use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

struct Entry {
    value: String,
    /// 0 = 永不过期；否则为 epoch 毫秒
    expiry_ms: u64,
}

static CACHE: Lazy<Mutex<HashMap<String, Entry>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

pub fn put(key: &str, value: &str, seconds: i64) {
    let expiry_ms = if seconds > 0 {
        now_ms().saturating_add((seconds as u64).saturating_mul(1000))
    } else {
        0
    };
    if let Ok(mut map) = CACHE.lock() {
        map.insert(
            key.to_string(),
            Entry {
                value: value.to_string(),
                expiry_ms,
            },
        );
    }
}

pub fn get(key: &str) -> String {
    let Ok(mut map) = CACHE.lock() else {
        return String::new();
    };
    let expired = match map.get(key) {
        Some(e) if e.expiry_ms > 0 && now_ms() > e.expiry_ms => true,
        Some(_) => false,
        None => return String::new(),
    };
    if expired {
        map.remove(key);
        return String::new();
    }
    map.get(key).map(|e| e.value.clone()).unwrap_or_default()
}

pub fn delete(key: &str) {
    if let Ok(mut map) = CACHE.lock() {
        map.remove(key);
    }
}

pub fn clear() {
    if let Ok(mut map) = CACHE.lock() {
        map.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[serial_test::serial(js_cache)]
    fn put_get_and_ttl() {
        clear();
        put("k", "v", 0);
        assert_eq!(get("k"), "v");
        delete("k");
        assert_eq!(get("k"), "");
    }
}
