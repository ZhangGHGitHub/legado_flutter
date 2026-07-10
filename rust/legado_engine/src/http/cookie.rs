use std::collections::HashMap;

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
}

fn extract_domain(url: &str) -> String {
    url::Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| h.to_lowercase()))
        .unwrap_or_default()
}

fn domain_chain(domain: &str) -> Vec<String> {
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
