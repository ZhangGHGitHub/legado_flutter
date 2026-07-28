use crate::http::network_config;
use legado_webdav::{WebDavClient, WebDavItem, WebDavProxy};

/// WebDAV 文件条目
#[derive(Debug, Clone)]
pub struct WebDavEntry {
    pub name: String,
    pub path: String,
    pub is_dir: bool,
    pub size: i32,
    pub last_modified: i64,
    pub etag: Option<String>,
}

fn map_items(items: Vec<WebDavItem>) -> Vec<WebDavEntry> {
    items
        .into_iter()
        .map(|i| WebDavEntry {
            name: i.name,
            path: i.path,
            is_dir: i.is_dir,
            size: i.size as i32,
            last_modified: i.last_modified,
            etag: i.etag,
        })
        .collect()
}

fn build_webdav_proxy() -> Option<WebDavProxy> {
    let cfg = network_config::get_network_config();
    network_config::build_proxy_url(&cfg).map(|url| WebDavProxy {
        url,
        username: cfg.proxy_username,
        password: cfg.proxy_password,
    })
}

fn new_webdav_client(url: &str, username: &str, password: &str) -> Result<WebDavClient, String> {
    let proxy = build_webdav_proxy();
    WebDavClient::new_with_proxy(url, username, password, proxy.as_ref()).map_err(|e| e.to_string())
}

/// 列出 WebDAV 目录
#[flutter_rust_bridge::frb]
pub async fn webdav_list(
    url: String,
    username: String,
    password: String,
    path: String,
) -> Result<Vec<WebDavEntry>, String> {
    let client = new_webdav_client(&url, &username, &password)?;
    let items = client.list(&path).await.map_err(|e| e.to_string())?;
    Ok(map_items(items))
}

/// 验证 WebDAV 目录访问权限
#[flutter_rust_bridge::frb]
pub async fn webdav_check(
    url: String,
    username: String,
    password: String,
    path: String,
) -> Result<(), String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client.check(&path).await.map_err(|e| e.to_string())
}

/// 确保 WebDAV 目录存在
#[flutter_rust_bridge::frb]
pub async fn webdav_ensure_dir(
    url: String,
    username: String,
    password: String,
    path: String,
) -> Result<(), String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client.ensure_dir(&path).await.map_err(|e| e.to_string())
}

/// 上传文件到 WebDAV
#[flutter_rust_bridge::frb]
pub async fn webdav_upload(
    url: String,
    username: String,
    password: String,
    remote_path: String,
    data: Vec<u8>,
) -> Result<(), String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client
        .upload(&data, &remote_path)
        .await
        .map_err(|e| e.to_string())
}

/// 按 ETag 条件上传文件，避免覆盖其他设备的更新。
#[flutter_rust_bridge::frb]
pub async fn webdav_upload_if_match(
    url: String,
    username: String,
    password: String,
    remote_path: String,
    data: Vec<u8>,
    etag: Option<String>,
) -> Result<(), String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client
        .upload_with_etag(&data, &remote_path, etag.as_deref())
        .await
        .map_err(|e| e.to_string())
}

/// 从 WebDAV 下载文件
#[flutter_rust_bridge::frb]
pub async fn webdav_download(
    url: String,
    username: String,
    password: String,
    remote_path: String,
) -> Result<Vec<u8>, String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client
        .download(&remote_path)
        .await
        .map_err(|e| e.to_string())
}

/// 删除 WebDAV 文件
#[flutter_rust_bridge::frb]
pub async fn webdav_delete(
    url: String,
    username: String,
    password: String,
    remote_path: String,
) -> Result<(), String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client.delete(&remote_path).await.map_err(|e| e.to_string())
}

/// 重命名 WebDAV 文件
#[flutter_rust_bridge::frb]
pub async fn webdav_move(
    url: String,
    username: String,
    password: String,
    remote_path: String,
    destination_path: String,
) -> Result<(), String> {
    let client = new_webdav_client(&url, &username, &password)?;
    client
        .move_to(&remote_path, &destination_path)
        .await
        .map_err(|e| e.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::http::network_config::{self, NetworkConfig};
    use serial_test::serial;

    #[test]
    #[serial]
    fn disabled_network_proxy_keeps_webdav_client_constructible_without_proxy() {
        network_config::set_network_config(NetworkConfig::default()).unwrap();
        assert!(build_webdav_proxy().is_none());
        new_webdav_client("https://dav.example.com/", "", "").unwrap();
    }

    #[test]
    #[serial]
    fn network_proxy_is_mapped_to_webdav_with_credentials() {
        let cfg = NetworkConfig {
            proxy_enabled: true,
            proxy_type: "socks5".into(),
            proxy_host: "127.0.0.1".into(),
            proxy_port: 1080,
            proxy_username: "proxy-user".into(),
            proxy_password: "proxy-pass".into(),
            ..Default::default()
        };
        network_config::set_network_config(cfg).unwrap();

        let proxy = build_webdav_proxy().unwrap();
        assert_eq!(proxy.url, "socks5://127.0.0.1:1080");
        assert_eq!(proxy.username, "proxy-user");
        assert_eq!(proxy.password, "proxy-pass");
        new_webdav_client("https://dav.example.com/", "", "").unwrap();

        network_config::set_network_config(NetworkConfig::default()).unwrap();
    }
}
