use crate::http::client;
use crate::http::network_config::{self, NetworkConfig};
use crate::rule::js_engine;

/// 网络配置 DTO
#[derive(Debug, Clone)]
pub struct NetworkConfigDto {
    pub proxy_enabled: bool,
    pub proxy_type: String,
    pub proxy_host: String,
    pub proxy_port: i32,
    pub proxy_username: String,
    pub proxy_password: String,
    pub dns_servers: String,
}

/// 应用代理 / DNS 配置
#[flutter_rust_bridge::frb(sync)]
pub fn set_network_config(
    proxy_enabled: bool,
    proxy_type: String,
    proxy_host: String,
    proxy_port: i32,
    proxy_username: String,
    proxy_password: String,
    dns_servers: String,
) -> Result<(), String> {
    network_config::set_network_config(NetworkConfig {
        proxy_enabled,
        proxy_type,
        proxy_host,
        proxy_port: proxy_port.max(0) as u16,
        proxy_username,
        proxy_password,
        dns_servers,
    })
}

/// 清空 HTTP Cookie 与 JS 内存缓存
#[flutter_rust_bridge::frb(sync)]
pub fn clear_engine_cache() -> Result<(), String> {
    client::clear_http_cookies()?;
    js_engine::reset_cache()?;
    Ok(())
}

/// 开启一次 debug HTTP 请求轨迹采集。
#[flutter_rust_bridge::frb(sync)]
pub fn start_http_request_trace() -> Result<(), String> {
    client::start_request_trace()
}

/// 停止并取出 debug HTTP 请求轨迹 JSON。
#[flutter_rust_bridge::frb(sync)]
pub fn drain_http_request_trace() -> String {
    client::drain_request_trace()
}

/// 当前网络配置
#[flutter_rust_bridge::frb(sync)]
pub fn get_network_config() -> NetworkConfigDto {
    let cfg = network_config::get_network_config();
    NetworkConfigDto {
        proxy_enabled: cfg.proxy_enabled,
        proxy_type: cfg.proxy_type,
        proxy_host: cfg.proxy_host,
        proxy_port: cfg.proxy_port as i32,
        proxy_username: cfg.proxy_username,
        proxy_password: cfg.proxy_password,
        dns_servers: cfg.dns_servers,
    }
}
