//! 登录头缓存 — 对齐 Jingshiro `CacheManager` key `loginHeader_${sourceKey}`
//!
//! 由 `source.putLoginHeader`（loginCheckJs / 登录 UI）写入；
//! `build_source_headers` / ajax 读取，避免仅依赖 Dart SharedPreferences 的竞态。

use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::sync::Mutex;

static STORE: Lazy<Mutex<HashMap<String, String>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

/// 本会话内由 loginCheckJs 新写入、待 Dart 回写 SourceLoginPrefs 的条目
static DIRTY: Lazy<Mutex<HashMap<String, String>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

pub fn get(source_key: &str) -> String {
    let key = source_key.trim();
    if key.is_empty() {
        return String::new();
    }
    STORE
        .lock()
        .ok()
        .and_then(|m| m.get(key).cloned())
        .unwrap_or_default()
}

pub fn put(source_key: &str, header: &str) {
    let key = source_key.trim();
    if key.is_empty() {
        return;
    }
    let header = header.to_string();
    if let Ok(mut m) = STORE.lock() {
        m.insert(key.to_string(), header.clone());
    }
    if let Ok(mut d) = DIRTY.lock() {
        d.insert(key.to_string(), header);
    }
}

/// 取出并清空待同步到 Flutter 的登录头（JSON object: url → header）
pub fn drain_dirty_json() -> String {
    let Ok(mut d) = DIRTY.lock() else {
        return "{}".to_string();
    };
    let map: HashMap<String, String> = d.drain().collect();
    serde_json::to_string(&map).unwrap_or_else(|_| "{}".to_string())
}

/// 预热：Dart 侧已持久化的登录头灌入 Rust（不标 dirty）
pub fn seed(source_key: &str, header: &str) {
    let key = source_key.trim();
    let header = header.trim();
    if key.is_empty() || header.is_empty() {
        return;
    }
    if let Ok(mut m) = STORE.lock() {
        m.insert(key.to_string(), header.to_string());
    }
}

pub fn clear() {
    if let Ok(mut m) = STORE.lock() {
        m.clear();
    }
    if let Ok(mut d) = DIRTY.lock() {
        d.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn put_get_drain() {
        clear();
        put("https://a.com", r#"{"Cookie":"x=1"}"#);
        assert!(get("https://a.com").contains("x=1"));
        let dirty = drain_dirty_json();
        assert!(dirty.contains("https://a.com"));
        assert_eq!(drain_dirty_json(), "{}");
    }
}
