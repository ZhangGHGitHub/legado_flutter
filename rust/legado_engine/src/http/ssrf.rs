//! 书源 HTTP 请求的基础 SSRF 防护（不约束 Web API 本机监听）。

use std::net::IpAddr;
use url::Host;

/// 若 URL 指向明显内网 / 回环 / 链路本地目标则返回错误。
pub fn assert_public_http_url(url: &str) -> Result<(), String> {
    let trimmed = url.trim();
    let parsed = url::Url::parse(trimmed).map_err(|_| "无效的 URL".to_string())?;
    let scheme = parsed.scheme().to_ascii_lowercase();
    if scheme != "http" && scheme != "https" {
        return Err("仅允许 http/https 请求".to_string());
    }
    let host = match parsed.host() {
        Some(host) => host,
        None => return Err("无效的 URL".to_string()),
    };
    // 仅给 crate 单元测试的本地 HTTP fixture 放行带显式端口的 loopback。
    // 正式构建没有这段 cfg，生产网络策略仍拒绝所有 loopback/private host。
    #[cfg(test)]
    if matches!(host, Host::Ipv4(address) if address.is_loopback()) && parsed.port().is_some() {
        return Ok(());
    }

    match host {
        Host::Domain(domain) if domain.eq_ignore_ascii_case("localhost") => {
            Err("禁止访问本机/回环地址（SSRF 防护）: localhost".to_string())
        }
        Host::Domain(_) => Ok(()),
        Host::Ipv4(address) => assert_public_ip(IpAddr::V4(address)),
        Host::Ipv6(address) => assert_public_ip(IpAddr::V6(address)),
    }
}

pub(crate) fn assert_public_ip(address: IpAddr) -> Result<(), String> {
    let blocked = match address {
        IpAddr::V4(address) => {
            let [a, b, ..] = address.octets();
            address.is_loopback()
                || address.is_private()
                || address.is_link_local()
                || address.is_unspecified()
                || (a == 100 && (64..=127).contains(&b))
        }
        IpAddr::V6(address) => {
            if let Some(mapped) = address.to_ipv4_mapped() {
                return assert_public_ip(IpAddr::V4(mapped));
            }
            address.is_loopback()
                || address.is_unspecified()
                || address.is_unique_local()
                || address.is_unicast_link_local()
                || address.is_multicast()
        }
    };
    if blocked {
        return Err(format!("禁止访问内网/私有地址（SSRF 防护）: {address}"));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn allows_public_https() {
        assert!(assert_public_http_url("https://example.com/search").is_ok());
    }

    #[test]
    fn blocks_localhost() {
        assert!(assert_public_http_url("http://localhost:8080/x").is_err());
        assert!(assert_public_http_url("http://127.0.0.1/x").is_err());
    }

    #[test]
    fn blocks_private_ranges() {
        assert!(assert_public_http_url("http://10.0.0.1/").is_err());
        assert!(assert_public_http_url("http://192.168.1.1/").is_err());
        assert!(assert_public_http_url("http://172.16.0.1/").is_err());
        assert!(assert_public_http_url("http://169.254.1.1/").is_err());
        assert!(assert_public_http_url("http://100.64.0.1/").is_err());
    }

    #[test]
    fn blocks_private_and_mapped_ipv6_literals() {
        assert!(assert_public_http_url("http://[::1]/").is_err());
        assert!(assert_public_http_url("http://[fc00::1]/").is_err());
        assert!(assert_public_http_url("http://[fe80::1]/").is_err());
        assert!(assert_public_http_url("http://[::ffff:127.0.0.1]/").is_err());
        assert!(assert_public_http_url("http://[2606:4700:4700::1111]/").is_ok());
    }

    #[test]
    fn allows_public_ipv4() {
        assert!(assert_public_http_url("http://8.8.8.8/dns").is_ok());
    }
}
