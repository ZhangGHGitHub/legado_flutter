use std::collections::HashMap;
use std::net::IpAddr;

#[derive(Clone)]
struct Cookie {
    value: String,
    domain: String,
    path: String,
    expiry: i64,
}

/// Legado 兼容 Cookie 存储
pub struct CookieJar {
    cookies: HashMap<String, HashMap<String, Cookie>>,
}

impl CookieJar {
    pub fn new() -> Self {
        Self {
            cookies: HashMap::new(),
        }
    }

    pub fn save_from_headers(&mut self, url: &str, set_cookies: &[String]) {
        let domain = extract_domain(url);
        if domain.is_empty() {
            return;
        }
        for header in set_cookies {
            self.parse_and_store(&domain, header);
        }
    }

    pub fn get_cookie(&self, url: &str) -> String {
        let domain = extract_domain(url);
        if domain.is_empty() {
            return String::new();
        }

        let now = chrono_now_ms();
        let mut parts = Vec::new();

        for d in domain_chain(&domain) {
            if let Some(domain_cookies) = self.cookies.get(&d) {
                for (name, cookie) in domain_cookies {
                    if cookie.expiry > 0 && now > cookie.expiry {
                        continue;
                    }
                    parts.push(format!("{name}={}", cookie.value));
                }
            }
        }
        parts.join("; ")
    }

    /// 按书源 key 的 eTLD+1（IP 保持自身）读取 Cookie。
    pub fn get_cookie_for_source(&self, source_url: &str) -> String {
        let Some(source_key) = source_cookie_key(source_url) else {
            return String::new();
        };
        let now = chrono_now_ms();
        let mut merged = HashMap::new();
        let mut domains: Vec<&String> = self
            .cookies
            .keys()
            .filter(|domain| source_cookie_key_from_host(domain).as_deref() == Some(&source_key))
            .collect();
        domains.sort_by(|left, right| {
            (left.as_str() != source_key, left.len(), left.as_str()).cmp(&(
                right.as_str() != source_key,
                right.len(),
                right.as_str(),
            ))
        });

        for domain in domains {
            if let Some(domain_cookies) = self.cookies.get(domain) {
                for (name, cookie) in domain_cookies {
                    if cookie.expiry > 0 && now > cookie.expiry {
                        continue;
                    }
                    merged.insert(name.clone(), cookie.value.clone());
                }
            }
        }
        format_flat_cookies(&merged)
    }

    /// 用扁平 Cookie 整串替换书源 eTLD+1 桶；空串等价于清除。
    pub fn set_cookie_for_source(&mut self, source_url: &str, cookie: &str) -> Result<(), String> {
        let source_key = require_source_cookie_key(source_url)?;
        self.clear_source_key(&source_key);
        self.store_flat_cookies(&source_key, cookie);
        Ok(())
    }

    /// 将扁平 Cookie 合并进书源 eTLD+1 桶，同名键以新值覆盖。
    pub fn merge_cookie_for_source(
        &mut self,
        source_url: &str,
        cookie: &str,
    ) -> Result<(), String> {
        let source_key = require_source_cookie_key(source_url)?;
        self.store_flat_cookies(&source_key, cookie);
        Ok(())
    }

    /// 清除且仅清除目标书源 eTLD+1 桶。
    pub fn clear_cookie_for_source(&mut self, source_url: &str) -> Result<(), String> {
        let source_key = require_source_cookie_key(source_url)?;
        self.clear_source_key(&source_key);
        Ok(())
    }

    /// 读取指定 Cookie 原始值（与 Set-Cookie 中一致，不作 URL decode）
    pub fn get_cookie_value(&self, url: &str, name: &str) -> Option<String> {
        let domain = extract_domain(url);
        if domain.is_empty() {
            return None;
        }
        let now = chrono_now_ms();
        for d in domain_chain(&domain) {
            if let Some(domain_cookies) = self.cookies.get(&d) {
                if let Some(cookie) = domain_cookies.get(name) {
                    if cookie.expiry > 0 && now > cookie.expiry {
                        continue;
                    }
                    return Some(cookie.value.clone());
                }
            }
        }
        None
    }

    fn parse_and_store(&mut self, domain: &str, header: &str) {
        let parts: Vec<&str> = header.split(';').collect();
        if parts.is_empty() {
            return;
        }

        let first = parts[0];
        let Some((name, value)) = first.split_once('=') else {
            return;
        };
        let name = name.trim();
        let value = value.trim();
        if name.is_empty() {
            return;
        }

        let mut cookie_domain = domain.to_string();
        let mut expiry: i64 = 0;

        for part in &parts[1..] {
            let part = part.trim();
            if let Some((key, val)) = part.split_once('=') {
                match key.trim().to_lowercase().as_str() {
                    "domain" => {
                        let mut d = val.trim().to_string();
                        if d.starts_with('.') {
                            d = d[1..].to_string();
                        }
                        cookie_domain = d.to_lowercase();
                    }
                    "max-age" => {
                        if let Ok(secs) = val.trim().parse::<i64>() {
                            expiry = chrono_now_ms() + secs * 1000;
                        }
                    }
                    _ => {}
                }
            }
        }

        let cookie = Cookie {
            value: value.to_string(),
            domain: cookie_domain.clone(),
            path: "/".to_string(),
            expiry,
        };

        self.cookies
            .entry(cookie_domain)
            .or_default()
            .insert(name.to_string(), cookie);
    }

    fn store_flat_cookies(&mut self, source_key: &str, cookie: &str) {
        for (name, value) in parse_flat_cookies(cookie) {
            self.cookies
                .entry(source_key.to_string())
                .or_default()
                .insert(
                    name,
                    Cookie {
                        value,
                        domain: source_key.to_string(),
                        path: "/".to_string(),
                        expiry: 0,
                    },
                );
        }
    }

    fn clear_source_key(&mut self, source_key: &str) {
        self.cookies
            .retain(|domain, _| source_cookie_key_from_host(domain).as_deref() != Some(source_key));
    }
}

fn require_source_cookie_key(source_url: &str) -> Result<String, String> {
    source_cookie_key(source_url).ok_or_else(|| "无效的书源 URL".to_string())
}

pub fn source_cookie_domain(source_url: &str) -> Result<String, String> {
    require_source_cookie_key(source_url)
}

fn source_cookie_key(source_url: &str) -> Option<String> {
    let parsed = url::Url::parse(source_url.trim()).ok()?;
    match parsed.host()? {
        url::Host::Ipv4(address) => Some(address.to_string()),
        url::Host::Ipv6(address) => Some(address.to_string()),
        url::Host::Domain(host) => source_cookie_key_from_host(host),
    }
}

fn source_cookie_key_from_host(host: &str) -> Option<String> {
    let host = host
        .trim()
        .trim_start_matches('[')
        .trim_end_matches(']')
        .trim_end_matches('.')
        .to_ascii_lowercase();
    if host.is_empty() {
        return None;
    }
    if host.parse::<IpAddr>().is_ok() {
        return Some(host);
    }
    psl::domain(host.as_bytes())
        .and_then(|domain| std::str::from_utf8(domain.as_bytes()).ok())
        .map(str::to_string)
        .or(Some(host))
}

fn parse_flat_cookies(cookie: &str) -> HashMap<String, String> {
    cookie
        .split(';')
        .filter_map(|part| {
            let (name, value) = part.trim().split_once('=')?;
            let name = name.trim();
            (!name.is_empty()).then(|| (name.to_string(), value.trim().to_string()))
        })
        .collect()
}

fn format_flat_cookies(cookies: &HashMap<String, String>) -> String {
    let mut parts: Vec<String> = cookies
        .iter()
        .map(|(name, value)| format!("{name}={value}"))
        .collect();
    parts.sort();
    parts.join("; ")
}

fn extract_domain(url: &str) -> String {
    url::Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| h.to_lowercase()))
        .unwrap_or_default()
}

fn domain_chain(domain: &str) -> Vec<String> {
    if domain.parse::<IpAddr>().is_ok() {
        return vec![domain.to_string()];
    }
    let parts: Vec<&str> = domain.split('.').collect();
    let mut chain = Vec::new();
    for i in 0..parts.len().saturating_sub(1) {
        chain.push(parts[i..].join("."));
    }
    chain
}

fn chrono_now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn get_cookie_value_keeps_urlencoded() {
        let mut jar = CookieJar::new();
        jar.save_from_headers(
            "https://www.rrssk.com/k-x.html",
            &["ge_ua_p=%2Babc%2Fxyz; Path=/; Max-Age=3600".to_string()],
        );
        assert_eq!(
            jar.get_cookie_value("https://www.rrssk.com/", "ge_ua_p")
                .as_deref(),
            Some("%2Babc%2Fxyz")
        );
        jar.save_from_headers(
            "https://www.rrssk.com/",
            &["ge_ua_key=%2Bkey; Path=/; Domain=rrssk.com; Max-Age=3600".to_string()],
        );
        assert_eq!(
            jar.get_cookie_value("https://www.rrssk.com/a", "ge_ua_key")
                .as_deref(),
            Some("%2Bkey")
        );
    }

    #[test]
    fn source_cookie_uses_public_suffix_and_shares_across_subdomains() {
        let mut jar = CookieJar::new();
        jar.set_cookie_for_source("https://login.reader.example.co.uk/path", "sid=shared")
            .unwrap();

        assert_eq!(
            jar.get_cookie_for_source("https://api.example.co.uk/books"),
            "sid=shared"
        );
        assert!(jar
            .get_cookie_for_source("https://api.example.com/books")
            .is_empty());
    }

    #[test]
    fn source_cookie_set_replaces_old_keys_and_empty_value_clears() {
        let mut jar = CookieJar::new();
        jar.set_cookie_for_source("https://www.example.com", "a=1; stale=old")
            .unwrap();
        jar.set_cookie_for_source("https://login.example.com", "a=2; fresh=new")
            .unwrap();
        assert_eq!(
            jar.get_cookie_for_source("https://reader.example.com"),
            "a=2; fresh=new"
        );

        jar.set_cookie_for_source("https://example.com", "")
            .unwrap();
        assert!(jar
            .get_cookie_for_source("https://reader.example.com")
            .is_empty());
    }

    #[test]
    fn source_cookie_merge_and_clear_are_scoped_to_target_registrable_domain() {
        let mut jar = CookieJar::new();
        jar.set_cookie_for_source("https://a.example.com", "a=1; shared=old")
            .unwrap();
        jar.merge_cookie_for_source("https://b.example.com", "b=2; shared=new")
            .unwrap();
        jar.set_cookie_for_source("https://other.example.net", "keep=yes")
            .unwrap();

        assert_eq!(
            jar.get_cookie_for_source("https://c.example.com"),
            "a=1; b=2; shared=new"
        );
        jar.clear_cookie_for_source("https://login.example.com")
            .unwrap();
        assert!(jar
            .get_cookie_for_source("https://c.example.com")
            .is_empty());
        assert_eq!(
            jar.get_cookie_for_source("https://other.example.net"),
            "keep=yes"
        );
    }

    #[test]
    fn source_cookie_session_value_overrides_persisted_value() {
        let mut jar = CookieJar::new();
        jar.set_cookie_for_source("https://www.example.com", "sid=persisted")
            .unwrap();
        jar.save_from_headers(
            "https://api.example.com/login",
            &["sid=session; Path=/".to_string()],
        );

        assert_eq!(
            jar.get_cookie_for_source("https://reader.example.com"),
            "sid=session"
        );
    }

    #[test]
    fn source_cookie_keeps_ip_as_its_own_bucket() {
        let mut jar = CookieJar::new();
        jar.set_cookie_for_source("http://127.0.0.1:8080/login", "sid=v4")
            .unwrap();
        jar.set_cookie_for_source("http://127.0.0.2:8080/login", "sid=other")
            .unwrap();
        jar.set_cookie_for_source("http://[::1]:8080/login", "sid=v6")
            .unwrap();

        assert_eq!(
            jar.get_cookie_for_source("http://127.0.0.1:9000/books"),
            "sid=v4"
        );
        assert_eq!(
            jar.get_cookie_for_source("http://127.0.0.2:9000/books"),
            "sid=other"
        );
        assert_eq!(
            jar.get_cookie_for_source("http://[::1]:9000/books"),
            "sid=v6"
        );
        assert_eq!(
            source_cookie_key("http://[::1]:8080/login").as_deref(),
            Some("::1")
        );
    }
}
