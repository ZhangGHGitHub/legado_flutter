use legado_webdav::{WebDavClient, WebDavItem};

/// WebDAV 文件条目
#[derive(Debug, Clone)]
pub struct WebDavEntry {
    pub name: String,
    pub path: String,
    pub is_dir: bool,
    pub size: i32,
    pub last_modified: i64,
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
        })
        .collect()
}

/// 列出 WebDAV 目录
#[flutter_rust_bridge::frb]
pub async fn webdav_list(
    url: String,
    username: String,
    password: String,
    path: String,
) -> Result<Vec<WebDavEntry>, String> {
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
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
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
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
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
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
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
    client
        .upload(&data, &remote_path)
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
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
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
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
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
    let client = WebDavClient::new(&url, &username, &password).map_err(|e| e.to_string())?;
    client
        .move_to(&remote_path, &destination_path)
        .await
        .map_err(|e| e.to_string())
}
