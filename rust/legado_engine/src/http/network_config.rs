use std::sync::Mutex;

use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};

/// 网络配置（代理 / DNS 记录）
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NetworkConfig {
    pub proxy_enabled: bool,
    /// `http` | `socks5`
    pub proxy_type: String,
    pub proxy_host: String,
    pub proxy_port: u16,
    pub proxy_username: String,
    pub proxy_password: String,
    /// 逗号分隔 DNS，如 `8.8.8.8,1.1.1.1`（当前版本持久化，解析待后续）
    pub dns_servers: String,
}

static CONFIG: Lazy<Mutex<NetworkConfig>> = Lazy::new(|| Mutex::new(NetworkConfig::default()));

pub fn get_network_config() -> NetworkConfig {
    CONFIG.lock().unwrap().clone()
}

pub fn set_network_config(cfg: NetworkConfig) -> Result<(), String> {
    *CONFIG.lock().map_err(|_| "网络配置锁失败".to_string())? = cfg;
    crate::http::client::rebuild_http_client()?;
    Ok(())
}

pub fn build_proxy_url(cfg: &NetworkConfig) -> Option<String> {
    if !cfg.proxy_enabled || cfg.proxy_host.trim().is_empty() || cfg.proxy_port == 0 {
        return None;
    }
    let scheme = if cfg.proxy_type.eq_ignore_ascii_case("socks5") {
        "socks5"
    } else {
        "http"
    };
    Some(format!(
        "{scheme}://{}:{}",
        cfg.proxy_host.trim(),
        cfg.proxy_port
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_proxy_url_http() {
        let cfg = NetworkConfig {
            proxy_enabled: true,
            proxy_type: "http".into(),
            proxy_host: "127.0.0.1".into(),
            proxy_port: 7890,
            ..Default::default()
        };
        assert_eq!(
            build_proxy_url(&cfg).as_deref(),
            Some("http://127.0.0.1:7890")
        );
    }
}
