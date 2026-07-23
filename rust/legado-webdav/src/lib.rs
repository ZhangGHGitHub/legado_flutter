use base64::{engine::general_purpose::STANDARD, Engine as _};
use quick_xml::events::Event;
use quick_xml::Reader;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use url::Url;

#[derive(Debug, Error)]
pub enum WebDavError {
    #[error("http: {0}")]
    Http(#[from] reqwest::Error),
    #[error("url: {0}")]
    Url(#[from] url::ParseError),
    #[error("{operation} 失败: HTTP {status}")]
    HttpStatus {
        operation: &'static str,
        status: u16,
    },
    #[error("{0}")]
    Message(String),
}

pub type Result<T> = std::result::Result<T, WebDavError>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebDavItem {
    pub name: String,
    pub path: String,
    pub is_dir: bool,
    pub size: i64,
    pub last_modified: i64,
}

pub struct WebDavClient {
    base_url: Url,
    username: String,
    password: String,
    client: Client,
}

impl WebDavClient {
    pub fn new(url: &str, username: &str, password: &str) -> Result<Self> {
        let mut base = Url::parse(url.trim())?;
        if base.path().is_empty() {
            base.set_path("/");
        }
        Ok(Self {
            base_url: base,
            username: username.to_string(),
            password: password.to_string(),
            client: Client::builder().build()?,
        })
    }

    pub async fn list(&self, path: &str) -> Result<Vec<WebDavItem>> {
        let target = self.join_path(path)?;
        let body = r#"<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getlastmodified/>
    <d:resourcetype/>
  </d:prop>
</d:propfind>"#;
        let resp = self
            .client
            .request(
                reqwest::Method::from_bytes(b"PROPFIND").unwrap(),
                target.clone(),
            )
            .headers(self.auth_headers()?)
            .header("Depth", "1")
            .header(CONTENT_TYPE, "application/xml; charset=utf-8")
            .body(body)
            .send()
            .await?;
        if !resp.status().is_success() {
            return Err(http_status_error("PROPFIND", resp.status()));
        }
        let text = resp.text().await?;
        Ok(parse_propfind(&text, &target))
    }

    pub async fn check(&self, path: &str) -> Result<()> {
        let status = self.propfind_status(path).await?;
        if status == reqwest::StatusCode::NOT_FOUND || status.is_success() {
            // A missing path is still an authenticated WebDAV endpoint; the
            // caller can create it with MKCOL.
            return Ok(());
        }
        Err(http_status_error("PROPFIND", status))
    }

    async fn propfind_status(&self, path: &str) -> Result<reqwest::StatusCode> {
        let target = self.join_path(path)?;
        let resp = self
            .client
            .request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), target)
            .headers(self.auth_headers()?)
            .header("Depth", "0")
            .header(CONTENT_TYPE, "application/xml; charset=utf-8")
            .body(PROPFIND_BODY)
            .send()
            .await?;
        Ok(resp.status())
    }

    pub async fn ensure_dir(&self, path: &str) -> Result<()> {
        let status = self.propfind_status(path).await?;
        if status.is_success() {
            return Ok(());
        }
        if status != reqwest::StatusCode::NOT_FOUND {
            return Err(http_status_error("PROPFIND", status));
        }

        let target = self.join_path(path)?;
        let resp = self
            .client
            .request(reqwest::Method::from_bytes(b"MKCOL").unwrap(), target)
            .headers(self.auth_headers()?)
            .send()
            .await?;
        if !resp.status().is_success() {
            return Err(http_status_error("创建目录", resp.status()));
        }
        Ok(())
    }

    pub async fn upload(&self, local: &[u8], remote: &str) -> Result<()> {
        let target = self.join_path(remote)?;
        let resp = self
            .client
            .put(target)
            .headers(self.auth_headers()?)
            .body(local.to_vec())
            .send()
            .await?;
        if !resp.status().is_success() {
            return Err(http_status_error("上传", resp.status()));
        }
        Ok(())
    }

    pub async fn download(&self, remote: &str) -> Result<Vec<u8>> {
        let target = self.join_path(remote)?;
        let resp = self
            .client
            .get(target)
            .headers(self.auth_headers()?)
            .send()
            .await?;
        if !resp.status().is_success() {
            return Err(http_status_error("下载", resp.status()));
        }
        Ok(resp.bytes().await?.to_vec())
    }

    pub async fn delete(&self, remote: &str) -> Result<()> {
        let target = self.join_path(remote)?;
        let resp = self
            .client
            .delete(target)
            .headers(self.auth_headers()?)
            .send()
            .await?;
        if !resp.status().is_success() && resp.status().as_u16() != 404 {
            return Err(http_status_error("删除", resp.status()));
        }
        Ok(())
    }

    pub async fn move_to(&self, remote: &str, destination: &str) -> Result<()> {
        let target = self.join_path(remote)?;
        let destination = self.join_path(destination)?;
        let resp = self
            .client
            .request(reqwest::Method::from_bytes(b"MOVE").unwrap(), target)
            .headers(self.auth_headers()?)
            .header("Destination", destination.as_str())
            .header("Overwrite", "F")
            .send()
            .await?;
        if !resp.status().is_success() {
            return Err(http_status_error("重命名", resp.status()));
        }
        Ok(())
    }

    fn auth_headers(&self) -> Result<HeaderMap> {
        let mut headers = HeaderMap::new();
        if !self.username.is_empty() || !self.password.is_empty() {
            let token = STANDARD.encode(format!("{}:{}", self.username, self.password));
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Basic {token}"))
                    .map_err(|e| WebDavError::Message(e.to_string()))?,
            );
        }
        Ok(headers)
    }

    fn join_path(&self, path: &str) -> Result<Url> {
        let p = path.trim();
        let rel = if p.is_empty() {
            "/".to_string()
        } else if p.starts_with('/') {
            p.to_string()
        } else {
            format!("/{p}")
        };
        let mut url = self.base_url.clone();
        url.set_path(&format!("{}{}", url.path().trim_end_matches('/'), rel));
        Ok(url)
    }
}

fn http_status_error(operation: &'static str, status: reqwest::StatusCode) -> WebDavError {
    WebDavError::HttpStatus {
        operation,
        status: status.as_u16(),
    }
}

const PROPFIND_BODY: &str = r#"<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getlastmodified/>
    <d:resourcetype/>
  </d:prop>
</d:propfind>"#;

fn parse_propfind(xml: &str, base: &Url) -> Vec<WebDavItem> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut items = Vec::new();
    let mut in_response = false;
    let mut href = String::new();
    let mut size: i64 = 0;
    let mut last_modified: i64 = 0;
    let mut is_dir = false;
    let mut in_collection = false;

    loop {
        match reader.read_event() {
            Ok(Event::Start(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                if name.ends_with("response") {
                    in_response = true;
                    href.clear();
                    size = 0;
                    last_modified = 0;
                    is_dir = false;
                    in_collection = false;
                } else if in_response && name.ends_with("collection") {
                    in_collection = true;
                }
            }
            Ok(Event::Text(t)) => {
                if !in_response {
                    continue;
                }
                let text = t.unescape().unwrap_or_default().to_string();
                // href captured on End
                let _ = text;
            }
            Ok(Event::End(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                if name.ends_with("href") && in_response {
                    // quick-xml doesn't give us text on End easily; use a simpler approach below
                } else if name.ends_with("getcontentlength") {
                    // handled via regex fallback
                } else if name.ends_with("response") {
                    if !href.is_empty() {
                        if let Some(item) = item_from_href(
                            &href,
                            base,
                            is_dir || in_collection,
                            size,
                            last_modified,
                        ) {
                            items.push(item);
                        }
                    }
                    in_response = false;
                }
            }
            Ok(Event::Empty(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                if name.ends_with("collection") {
                    in_collection = true;
                }
            }
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
    }

    if items.is_empty() {
        items = parse_propfind_regex(xml, base);
    }
    items
}

fn parse_propfind_regex(xml: &str, base: &Url) -> Vec<WebDavItem> {
    let mut items = Vec::new();
    let chunks: Vec<&str> = xml.split("<d:response").collect();
    for chunk in chunks.iter().skip(1) {
        let href = extract_tag(chunk, "d:href").or_else(|| extract_tag(chunk, "href"));
        let Some(href) = href else { continue };
        let is_dir = chunk.contains("<d:collection") || chunk.contains(":collection");
        let size = extract_tag(chunk, "d:getcontentlength")
            .or_else(|| extract_tag(chunk, "getcontentlength"))
            .and_then(|s| s.parse().ok())
            .unwrap_or(0);
        let last_modified = extract_tag(chunk, "d:getlastmodified")
            .or_else(|| extract_tag(chunk, "getlastmodified"))
            .and_then(|s| parse_http_date_millis(&s))
            .unwrap_or(0);
        if let Some(item) = item_from_href(&href, base, is_dir, size, last_modified) {
            items.push(item);
        }
    }
    items
}

fn extract_tag(xml: &str, tag: &str) -> Option<String> {
    let open = format!("<{tag}>");
    let close = format!("</{tag}>");
    let start = xml.find(&open)? + open.len();
    let end = xml[start..].find(&close)? + start;
    Some(xml[start..end].trim().to_string())
}

fn item_from_href(
    href: &str,
    base: &Url,
    is_dir: bool,
    size: i64,
    last_modified: i64,
) -> Option<WebDavItem> {
    let decoded = urlencoding_simple(href);
    let path = if let Ok(u) = Url::parse(&decoded) {
        u.path().to_string()
    } else {
        decoded
    };
    if path == base.path() || path.is_empty() {
        return None;
    }
    let name = path.trim_end_matches('/').rsplit('/').next()?.to_string();
    if name.is_empty() {
        return None;
    }
    Some(WebDavItem {
        name,
        path,
        is_dir,
        size,
        last_modified,
    })
}

fn parse_http_date_millis(value: &str) -> Option<i64> {
    let duration = httpdate::parse_http_date(value)
        .ok()?
        .duration_since(std::time::UNIX_EPOCH)
        .ok()?;
    i64::try_from(duration.as_millis()).ok()
}

fn urlencoding_simple(s: &str) -> String {
    s.replace("%20", " ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn join_path_works() {
        let client = WebDavClient::new("https://dav.example.com/remote", "u", "p").unwrap();
        let url = client.join_path("/legado/backup.json").unwrap();
        assert!(url.as_str().contains("backup.json"));
    }

    #[test]
    fn parse_propfind_extracts_files() {
        let xml = r#"<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/remote/legado/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/remote/legado/backup.json</d:href>
    <d:propstat><d:prop>
      <d:getcontentlength>1024</d:getcontentlength>
      <d:getlastmodified>Wed, 21 Oct 2015 07:28:00 GMT</d:getlastmodified>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>"#;
        let base = Url::parse("https://dav.example.com/remote/legado/").unwrap();
        let items = parse_propfind(xml, &base);
        let item = items
            .iter()
            .find(|i| i.name == "backup.json" && !i.is_dir)
            .unwrap();
        assert_eq!(item.size, 1024);
        assert_eq!(item.last_modified, 1_445_412_480_000);
    }

    #[test]
    fn invalid_last_modified_falls_back_to_zero() {
        let xml = r#"<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/remote/legado/backup.json</d:href>
    <d:propstat><d:prop>
      <d:getlastmodified>not-a-date</d:getlastmodified>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>"#;
        let base = Url::parse("https://dav.example.com/remote/legado/").unwrap();
        let items = parse_propfind(xml, &base);
        assert_eq!(items[0].last_modified, 0);
    }

    #[test]
    fn http_status_errors_preserve_operation_and_code() {
        assert_eq!(
            http_status_error("PROPFIND", reqwest::StatusCode::UNAUTHORIZED).to_string(),
            "PROPFIND 失败: HTTP 401"
        );
        assert_eq!(
            http_status_error("上传", reqwest::StatusCode::FORBIDDEN).to_string(),
            "上传 失败: HTTP 403"
        );
        assert_eq!(
            http_status_error("下载", reqwest::StatusCode::BAD_GATEWAY).to_string(),
            "下载 失败: HTTP 502"
        );
    }

    #[tokio::test]
    async fn check_and_ensure_dir_use_propfind_then_mkcol() {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        use tokio::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let mut requests = Vec::new();
            for _ in 0..3 {
                let (mut socket, _) = listener.accept().await.unwrap();
                let mut buffer = vec![0_u8; 8192];
                let size = socket.read(&mut buffer).await.unwrap();
                let request = String::from_utf8_lossy(&buffer[..size]).to_string();
                let first_line = request.lines().next().unwrap_or_default();
                let status = if first_line.starts_with("PROPFIND /remote/legado/bookProgress") {
                    "404 Not Found"
                } else if first_line.starts_with("MKCOL") {
                    "201 Created"
                } else {
                    "207 Multi-Status"
                };
                let response =
                    format!("HTTP/1.1 {status}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
                socket.write_all(response.as_bytes()).await.unwrap();
                requests.push(request);
            }
            requests
        });

        let client =
            WebDavClient::new(&format!("http://{address}/remote"), "account", "password").unwrap();
        client.check("/legado").await.unwrap();
        client.ensure_dir("/legado/bookProgress").await.unwrap();

        let requests = server.await.unwrap();
        assert!(requests[0].starts_with("PROPFIND /remote/legado "));
        assert!(requests[1].starts_with("PROPFIND /remote/legado/bookProgress "));
        assert!(requests[2].starts_with("MKCOL /remote/legado/bookProgress "));
        assert!(requests.iter().all(|request| {
            request.to_ascii_lowercase().contains("authorization:")
                && request.contains("Basic YWNjb3VudDpwYXNzd29yZA==")
        }));
    }

    #[tokio::test]
    async fn missing_root_check_allows_mkcol_creation() {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        use tokio::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let mut requests = Vec::new();
            for _ in 0..3 {
                let (mut socket, _) = listener.accept().await.unwrap();
                let mut buffer = vec![0_u8; 8192];
                let size = socket.read(&mut buffer).await.unwrap();
                let request = String::from_utf8_lossy(&buffer[..size]).to_string();
                let first_line = request.lines().next().unwrap_or_default();
                let status = if first_line.starts_with("MKCOL") {
                    "201 Created"
                } else {
                    "404 Not Found"
                };
                let response =
                    format!("HTTP/1.1 {status}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
                socket.write_all(response.as_bytes()).await.unwrap();
                requests.push(request);
            }
            requests
        });

        let client =
            WebDavClient::new(&format!("http://{address}/remote"), "account", "password").unwrap();
        client.check("/legado").await.unwrap();
        client.ensure_dir("/legado").await.unwrap();

        let requests = server.await.unwrap();
        assert!(requests[0].starts_with("PROPFIND /remote/legado "));
        assert!(requests[1].starts_with("PROPFIND /remote/legado "));
        assert!(requests[2].starts_with("MKCOL /remote/legado "));
    }

    #[tokio::test]
    async fn client_roundtrip_uses_webdav_paths_and_basic_auth() {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        use tokio::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let mut requests = Vec::new();
            for _ in 0..4 {
                let (mut socket, _) = listener.accept().await.unwrap();
                let mut buffer = vec![0_u8; 8192];
                let size = socket.read(&mut buffer).await.unwrap();
                let request = String::from_utf8_lossy(&buffer[..size]).to_string();
                let first_line = request.lines().next().unwrap_or_default();
                let (status, content_type, body) = if first_line.starts_with("PROPFIND") {
                    (
                        "207 Multi-Status",
                        "application/xml",
                        r#"<?xml version="1.0"?><d:multistatus xmlns:d="DAV:"><d:response><d:href>/remote/legado/bookmark.json</d:href><d:propstat><d:prop><d:getcontentlength>2</d:getcontentlength></d:prop></d:propstat></d:response></d:multistatus>"#,
                    )
                } else if first_line.starts_with("PUT") {
                    ("201 Created", "text/plain", "")
                } else if first_line.starts_with("MOVE") {
                    ("201 Created", "text/plain", "")
                } else {
                    ("200 OK", "application/json", "[]")
                };
                let response = format!(
                    "HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                    body.len()
                );
                socket.write_all(response.as_bytes()).await.unwrap();
                requests.push(request);
            }
            requests
        });

        let client =
            WebDavClient::new(&format!("http://{address}/remote"), "account", "password").unwrap();
        let entries = client.list("/legado").await.unwrap();
        assert_eq!(entries[0].name, "bookmark.json");
        client.upload(b"[]", "/legado/bookmark.json").await.unwrap();
        client
            .move_to("/legado/bookmark.json", "/legado/legado_backup_latest.json")
            .await
            .unwrap();
        assert_eq!(
            client
                .download("/legado/legado_backup_latest.json")
                .await
                .unwrap(),
            b"[]"
        );

        let requests = server.await.unwrap();
        assert!(requests.iter().all(|request| {
            request.to_ascii_lowercase().contains("authorization:")
                && request.contains("Basic YWNjb3VudDpwYXNzd29yZA==")
        }));
        assert!(requests[0].starts_with("PROPFIND /remote/legado "));
        assert!(requests[1].starts_with("PUT /remote/legado/bookmark.json "));
        assert!(requests[2].starts_with("MOVE /remote/legado/bookmark.json "));
        let move_request = requests[2].to_ascii_lowercase();
        assert!(move_request.contains("destination: http://"));
        assert!(requests[2].contains("/remote/legado/legado_backup_latest.json"));
        assert!(move_request.contains("overwrite: f"));
        assert!(requests[3].starts_with("GET /remote/legado/legado_backup_latest.json "));
    }
}
