use base64::{engine::general_purpose::STANDARD, Engine as _};
use quick_xml::events::Event;
use quick_xml::Reader;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE, IF_MATCH};
use reqwest::{Client, Proxy};
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
    pub etag: Option<String>,
}

/// Proxy settings shared with the engine's NetworkConfig.
#[derive(Debug, Clone)]
pub struct WebDavProxy {
    pub url: String,
    pub username: String,
    pub password: String,
}

pub struct WebDavClient {
    base_url: Url,
    username: String,
    password: String,
    client: Client,
}

impl WebDavClient {
    pub fn new(url: &str, username: &str, password: &str) -> Result<Self> {
        Self::new_with_proxy(url, username, password, None)
    }

    pub fn new_with_proxy(
        url: &str,
        username: &str,
        password: &str,
        proxy: Option<&WebDavProxy>,
    ) -> Result<Self> {
        let mut base = Url::parse(url.trim())?;
        if base.path().is_empty() {
            base.set_path("/");
        }

        let mut builder = Client::builder().no_proxy();
        if let Some(proxy_config) = proxy {
            let mut proxy = Proxy::all(&proxy_config.url)?;
            if !proxy_config.username.is_empty() {
                proxy = proxy.basic_auth(&proxy_config.username, &proxy_config.password);
            }
            builder = builder.proxy(proxy);
        }

        Ok(Self {
            base_url: base,
            username: username.to_string(),
            password: password.to_string(),
            client: builder.build()?,
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
    <d:getetag/>
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
        self.upload_with_etag(local, remote, None).await
    }

    pub async fn upload_with_etag(
        &self,
        local: &[u8],
        remote: &str,
        etag: Option<&str>,
    ) -> Result<()> {
        let target = self.join_path(remote)?;
        let mut request = self
            .client
            .put(target)
            .headers(self.auth_headers()?)
            .body(local.to_vec());
        if let Some(etag) = etag {
            request = request.header(IF_MATCH, etag);
        }
        let resp = request.send().await?;
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
        if !resp.status().is_success() {
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
    <d:getetag/>
    <d:resourcetype/>
  </d:prop>
</d:propfind>"#;

fn parse_propfind(xml: &str, base: &Url) -> Vec<WebDavItem> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut items = Vec::new();
    let mut response: Option<ResponseBuilder> = None;
    let mut field: Option<ResponseField> = None;
    let mut field_text = String::new();

    loop {
        match reader.read_event() {
            Ok(Event::Start(e)) => {
                let raw_name = e.name();
                let name = local_name(raw_name.as_ref());
                if name == b"response" {
                    response = Some(ResponseBuilder::default());
                    field = None;
                    field_text.clear();
                } else if let Some(current) = response.as_mut() {
                    if name == b"collection" {
                        current.is_dir = true;
                    }
                    if let Some(next_field) = ResponseField::from_local_name(name) {
                        field = Some(next_field);
                        field_text.clear();
                    }
                }
            }
            Ok(Event::Text(t)) => {
                if response.is_some() && field.is_some() {
                    field_text.push_str(&t.unescape().unwrap_or_default());
                }
            }
            Ok(Event::CData(t)) => {
                if response.is_some() && field.is_some() {
                    field_text.push_str(&String::from_utf8_lossy(t.as_ref()));
                }
            }
            Ok(Event::End(e)) => {
                let raw_name = e.name();
                let name = local_name(raw_name.as_ref());
                if let Some(current_field) = field {
                    if current_field.matches(name) {
                        if let Some(current) = response.as_mut() {
                            current.set_field(current_field, field_text.trim());
                        }
                        field = None;
                        field_text.clear();
                    }
                }
                if name == b"response" {
                    if let Some(current) = response.take() {
                        if let Some(item) = current.into_item(base) {
                            items.push(item);
                        }
                    }
                    field = None;
                    field_text.clear();
                }
            }
            Ok(Event::Empty(e)) => {
                if let Some(current) = response.as_mut() {
                    if local_name(e.name().as_ref()) == b"collection" {
                        current.is_dir = true;
                    }
                }
            }
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
    }
    items
}

#[derive(Debug, Default)]
struct ResponseBuilder {
    href: String,
    display_name: String,
    size: i64,
    last_modified: i64,
    etag: Option<String>,
    is_dir: bool,
}

#[derive(Debug, Clone, Copy)]
enum ResponseField {
    Href,
    DisplayName,
    ContentLength,
    LastModified,
    Etag,
}

impl ResponseField {
    fn from_local_name(name: &[u8]) -> Option<Self> {
        match name {
            b"href" => Some(Self::Href),
            b"displayname" => Some(Self::DisplayName),
            b"getcontentlength" => Some(Self::ContentLength),
            b"getlastmodified" => Some(Self::LastModified),
            b"getetag" => Some(Self::Etag),
            _ => None,
        }
    }

    fn matches(self, name: &[u8]) -> bool {
        matches!(
            (self, name),
            (Self::Href, b"href")
                | (Self::DisplayName, b"displayname")
                | (Self::ContentLength, b"getcontentlength")
                | (Self::LastModified, b"getlastmodified")
                | (Self::Etag, b"getetag")
        )
    }
}

impl ResponseBuilder {
    fn set_field(&mut self, field: ResponseField, value: &str) {
        match field {
            ResponseField::Href => self.href = value.to_string(),
            ResponseField::DisplayName => self.display_name = value.to_string(),
            ResponseField::ContentLength => self.size = value.parse().unwrap_or(0),
            ResponseField::LastModified => {
                self.last_modified = parse_http_date_millis(value).unwrap_or(0)
            }
            ResponseField::Etag => self.etag = (!value.is_empty()).then(|| value.to_string()),
        }
    }

    fn into_item(self, base: &Url) -> Option<WebDavItem> {
        item_from_href(
            &self.href,
            base,
            self.is_dir,
            self.size,
            self.last_modified,
            self.etag,
            (!self.display_name.trim().is_empty()).then_some(self.display_name),
        )
    }
}

fn item_from_href(
    href: &str,
    base: &Url,
    is_dir: bool,
    size: i64,
    last_modified: i64,
    etag: Option<String>,
    display_name: Option<String>,
) -> Option<WebDavItem> {
    let href = href.trim();
    if href.is_empty() {
        return None;
    }
    let href_url = resolve_href(href, base)?;
    let raw_path = href_url.path();
    if same_path(raw_path, base.path()) || raw_path.is_empty() {
        return None;
    }
    let mut path = raw_path.to_string();
    if is_dir && !path.ends_with('/') {
        path.push('/');
    }
    let href_name = raw_path
        .trim_end_matches('/')
        .rsplit('/')
        .next()
        .filter(|name| !name.is_empty())?;
    let name = display_name
        .filter(|name| !name.trim().is_empty())
        .map(|name| percent_decode(&name))
        .unwrap_or_else(|| percent_decode(href_name));
    if name.is_empty() {
        return None;
    }
    Some(WebDavItem {
        name,
        path,
        is_dir,
        size,
        last_modified,
        etag,
    })
}

fn local_name(name: &[u8]) -> &[u8] {
    name.rsplit(|byte| *byte == b':').next().unwrap_or(name)
}

fn resolve_href(href: &str, base: &Url) -> Option<Url> {
    if let Ok(url) = Url::parse(href) {
        return Some(url);
    }

    let mut base_dir = base.clone();
    let base_path = base.path();
    let directory_path = if base_path.ends_with('/') {
        base_path.to_string()
    } else {
        format!("{base_path}/")
    };
    base_dir.set_path(&directory_path);

    if href.starts_with('/') {
        let mut absolute_path = base.clone();
        absolute_path.set_path(href);
        Some(absolute_path)
    } else {
        base_dir.join(href).ok()
    }
}

fn percent_decode(value: &str) -> String {
    let bytes = value.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        if bytes[index] == b'%' && index + 2 < bytes.len() {
            if let (Some(high), Some(low)) =
                (hex_value(bytes[index + 1]), hex_value(bytes[index + 2]))
            {
                decoded.push((high << 4) | low);
                index += 3;
                continue;
            }
        }
        decoded.push(bytes[index]);
        index += 1;
    }
    String::from_utf8_lossy(&decoded).into_owned()
}

fn hex_value(value: u8) -> Option<u8> {
    match value {
        b'0'..=b'9' => Some(value - b'0'),
        b'a'..=b'f' => Some(value - b'a' + 10),
        b'A'..=b'F' => Some(value - b'A' + 10),
        _ => None,
    }
}

fn same_path(left: &str, right: &str) -> bool {
    trim_trailing_slash(left) == trim_trailing_slash(right)
}

fn trim_trailing_slash(path: &str) -> &str {
    if path == "/" {
        path
    } else {
        path.trim_end_matches('/')
    }
}

fn parse_http_date_millis(value: &str) -> Option<i64> {
    let duration = httpdate::parse_http_date(value)
        .ok()?
        .duration_since(std::time::UNIX_EPOCH)
        .ok()?;
    i64::try_from(duration.as_millis()).ok()
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
    fn client_constructs_with_http_and_socks5_proxy_auth() {
        let http_proxy = WebDavProxy {
            url: "http://127.0.0.1:7890".into(),
            username: "http-user".into(),
            password: "http-pass".into(),
        };
        WebDavClient::new_with_proxy("https://dav.example.com/", "", "", Some(&http_proxy))
            .unwrap();

        let socks5_proxy = WebDavProxy {
            url: "socks5://127.0.0.1:1080".into(),
            username: "socks-user".into(),
            password: "socks-pass".into(),
        };
        WebDavClient::new_with_proxy("https://dav.example.com/", "", "", Some(&socks5_proxy))
            .unwrap();
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
      <d:getetag>&quot;backup-v1&quot;</d:getetag>
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
        assert_eq!(item.etag.as_deref(), Some("\"backup-v1\""));
    }

    #[test]
    fn parse_propfind_is_namespace_agnostic_and_decodes_hrefs() {
        let xml = r#"<?xml version="1.0"?>
<multistatus xmlns="DAV:" xmlns:x="urn:server-dav">
  <response>
    <href><![CDATA[https://dav.example.com/remote/legado/dir%20name]]></href>
    <propstat><prop>
      <displayname>dir%20name</displayname>
      <resourcetype><x:collection/></resourcetype>
    </prop></propstat>
  </response>
  <response>
    <href>https://dav.example.com/remote/legado/a%2Fb%20name%26v.json?download=1&amp;raw=true</href>
    <propstat><prop>
      <getcontentlength>42</getcontentlength>
    </prop></propstat>
  </response>
</multistatus>"#;
        let base = Url::parse("https://dav.example.com/remote/legado").unwrap();

        let items = parse_propfind(xml, &base);

        let directory = items.iter().find(|item| item.is_dir).unwrap();
        assert_eq!(directory.name, "dir name");
        assert_eq!(directory.path, "/remote/legado/dir%20name/");

        let file = items.iter().find(|item| !item.is_dir).unwrap();
        assert_eq!(file.name, "a/b name&v.json");
        assert_eq!(file.path, "/remote/legado/a%2Fb%20name%26v.json");
        assert_eq!(file.size, 42);

        let client = WebDavClient::new("https://dav.example.com/", "", "").unwrap();
        let request_url = client.join_path(&file.path).unwrap();
        assert_eq!(request_url.path(), "/remote/legado/a%2Fb%20name%26v.json");
    }

    #[test]
    fn parse_propfind_resolves_relative_href_and_skips_base_response() {
        let xml = r#"<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/remote/legado/</D:href>
    <D:propstat><D:prop><D:resourcetype><D:collection/></D:resourcetype></D:prop></D:propstat>
  </D:response>
  <D:response>
    <D:href>backup%20&amp;%20one.json</D:href>
    <D:propstat><D:prop><D:displayname/></D:prop></D:propstat>
  </D:response>
</D:multistatus>"#;
        let base = Url::parse("https://dav.example.com/remote/legado/").unwrap();

        let items = parse_propfind(xml, &base);

        assert_eq!(items.len(), 1);
        assert_eq!(items[0].name, "backup & one.json");
        assert_eq!(items[0].path, "/remote/legado/backup%20&%20one.json");
        assert!(!items[0].is_dir);
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

    #[tokio::test]
    async fn conditional_upload_sends_if_match_and_preserves_412_status() {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        use tokio::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let mut requests = Vec::new();
            for status in ["201 Created", "412 Precondition Failed"] {
                let (mut socket, _) = listener.accept().await.unwrap();
                let mut buffer = vec![0_u8; 8192];
                let size = socket.read(&mut buffer).await.unwrap();
                requests.push(String::from_utf8_lossy(&buffer[..size]).to_string());
                let response =
                    format!("HTTP/1.1 {status}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
                socket.write_all(response.as_bytes()).await.unwrap();
            }
            requests
        });

        let client = WebDavClient::new(&format!("http://{address}/remote"), "", "").unwrap();
        client
            .upload_with_etag(b"first", "/legado/backup.json", None)
            .await
            .unwrap();
        let error = client
            .upload_with_etag(b"second", "/legado/backup.json", Some("\"backup-v1\""))
            .await
            .unwrap_err();

        match error {
            WebDavError::HttpStatus { operation, status } => {
                assert_eq!(operation, "上传");
                assert_eq!(status, 412);
            }
            other => panic!("expected structured HTTP status, got {other:?}"),
        }

        let requests = server.await.unwrap();
        assert!(!requests[0].to_ascii_lowercase().contains("if-match:"));
        assert!(requests[1]
            .to_ascii_lowercase()
            .contains("if-match: \"backup-v1\""));
    }

    async fn assert_http_status_from_mock<F, Fut>(
        status: &'static str,
        expected_method: &'static str,
        expected_error: &'static str,
        operation: F,
    ) where
        F: FnOnce(WebDavClient) -> Fut,
        Fut: std::future::Future<Output = Result<()>>,
    {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        use tokio::net::TcpListener;

        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let server = tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut buffer = vec![0_u8; 8192];
            let size = socket.read(&mut buffer).await.unwrap();
            let request = String::from_utf8_lossy(&buffer[..size]).to_string();
            let response =
                format!("HTTP/1.1 {status}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
            socket.write_all(response.as_bytes()).await.unwrap();
            request
        });

        let client =
            WebDavClient::new(&format!("http://{address}/remote"), "account", "password").unwrap();
        let error = operation(client).await.unwrap_err();
        assert_eq!(error.to_string(), expected_error);

        let request = server.await.unwrap();
        assert!(request.starts_with(expected_method));
        assert!(request
            .to_ascii_lowercase()
            .contains("authorization: basic ywnjb3vuddpwyxnzd29yza=="));
    }

    #[tokio::test]
    async fn operation_failures_preserve_http_status_and_stop_follow_up_requests() {
        assert_http_status_from_mock(
            "401 Unauthorized",
            "PROPFIND /remote/legado ",
            "PROPFIND 失败: HTTP 401",
            |client| async move { client.check("/legado").await },
        )
        .await;

        assert_http_status_from_mock(
            "405 Method Not Allowed",
            "PROPFIND /remote/legado/bookProgress ",
            "PROPFIND 失败: HTTP 405",
            |client| async move { client.ensure_dir("/legado/bookProgress").await },
        )
        .await;

        assert_http_status_from_mock(
            "501 Not Implemented",
            "PUT /remote/legado/backup.zip ",
            "上传 失败: HTTP 501",
            |client| async move { client.upload(b"payload", "/legado/backup.zip").await },
        )
        .await;

        assert_http_status_from_mock(
            "404 Not Found",
            "DELETE /remote/legado/backup.zip ",
            "删除 失败: HTTP 404",
            |client| async move { client.delete("/legado/backup.zip").await },
        )
        .await;
    }

    #[tokio::test]
    #[ignore = "requires scripts/start_local_webdav.ps1 or another real WebDAV endpoint"]
    async fn local_webdav_smoke_roundtrip() -> std::result::Result<(), Box<dyn std::error::Error>> {
        let url = std::env::var("LOCAL_WEBDAV_URL")
            .unwrap_or_else(|_| "http://127.0.0.1:19080/".to_string());
        let username = std::env::var("LOCAL_WEBDAV_USER").unwrap_or_else(|_| "legado".to_string());
        let password =
            std::env::var("LOCAL_WEBDAV_PASSWORD").unwrap_or_else(|_| "legado-test".to_string());
        let client = WebDavClient::new(&url, &username, &password)?;

        let stamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_millis();
        let root = format!("/codex-rust-smoke-{stamp}");
        let progress_dir = format!("{root}/bookProgress");
        let sample = format!("{progress_dir}/sample.json");
        let renamed = format!("{progress_dir}/sample-renamed.json");
        let etag_file = format!("{progress_dir}/etag.json");

        client.check(&root).await?;
        client.ensure_dir(&root).await?;
        client.ensure_dir(&progress_dir).await?;
        client.upload(br#"{"ok":true}"#, &sample).await?;

        let entries = client.list(&progress_dir).await?;
        assert!(entries
            .iter()
            .any(|entry| entry.name == "sample.json" && !entry.is_dir && entry.size > 0));

        assert_eq!(client.download(&sample).await?, br#"{"ok":true}"#);
        client.move_to(&sample, &renamed).await?;
        assert_eq!(client.download(&renamed).await?, br#"{"ok":true}"#);

        client.upload(b"v1", &etag_file).await?;
        let etag = client
            .list(&progress_dir)
            .await?
            .into_iter()
            .find(|entry| entry.name == "etag.json")
            .and_then(|entry| entry.etag)
            .expect("etag.json should include an ETag");
        client.upload_with_etag(b"v2", &etag_file, Some(&etag)).await?;

        let stale = client
            .upload_with_etag(b"v3", &etag_file, Some(&etag))
            .await
            .unwrap_err();
        match stale {
            WebDavError::HttpStatus { operation, status } => {
                assert_eq!(operation, "上传");
                assert_eq!(status, 412);
            }
            other => panic!("expected stale ETag to return HTTP 412, got {other:?}"),
        }

        client.delete(&root).await?;
        Ok(())
    }
}
