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
    <d:resourcetype/>
  </d:prop>
</d:propfind>"#;
        let resp = self
            .client
            .request(reqwest::Method::from_bytes(b"PROPFIND").unwrap(), target.clone())
            .headers(self.auth_headers()?)
            .header("Depth", "1")
            .header(CONTENT_TYPE, "application/xml; charset=utf-8")
            .body(body)
            .send()
            .await?;
        if !resp.status().is_success() {
            return Err(WebDavError::Message(format!(
                "PROPFIND 失败: {}",
                resp.status()
            )));
        }
        let text = resp.text().await?;
        Ok(parse_propfind(&text, &target))
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
            return Err(WebDavError::Message(format!("上传失败: {}", resp.status())));
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
            return Err(WebDavError::Message(format!("下载失败: {}", resp.status())));
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
            return Err(WebDavError::Message(format!("删除失败: {}", resp.status())));
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
        url.set_path(&format!(
            "{}{}",
            url.path().trim_end_matches('/'),
            rel
        ));
        Ok(url)
    }
}

fn parse_propfind(xml: &str, base: &Url) -> Vec<WebDavItem> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut items = Vec::new();
    let mut in_response = false;
    let mut href = String::new();
    let mut size: i64 = 0;
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
                        if let Some(item) = item_from_href(&href, base, is_dir || in_collection, size)
                        {
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
        if let Some(item) = item_from_href(&href, base, is_dir, size) {
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

fn item_from_href(href: &str, base: &Url, is_dir: bool, size: i64) -> Option<WebDavItem> {
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
    })
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
    <d:propstat><d:prop><d:getcontentlength>1024</d:getcontentlength></d:prop></d:propstat>
  </d:response>
</d:multistatus>"#;
        let base = Url::parse("https://dav.example.com/remote/legado/").unwrap();
        let items = parse_propfind_regex(xml, &base);
        assert!(items.iter().any(|i| i.name == "backup.json" && !i.is_dir));
    }
}
