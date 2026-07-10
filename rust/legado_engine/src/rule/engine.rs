use super::css;
use scraper::{ElementRef, Html, Selector};

/// 从 HTML 元素按规则提取文本
pub fn extract_text(element: &ElementRef<'_>, rule: &str) -> String {
    if rule.is_empty() {
        return String::new();
    }

    if rule.contains("||") {
        for part in split_top_level(rule, "||") {
            let result = extract_text(element, part.trim());
            if !result.is_empty() {
                return result;
            }
        }
        return String::new();
    }

    if rule.contains("&&") {
        return split_top_level(rule, "&&")
            .iter()
            .map(|p| extract_text(element, p.trim()))
            .collect::<Vec<_>>()
            .join("");
    }

    let mut processed = rule.trim().to_string();
    while processed.starts_with('@') && !processed.starts_with("@@") {
        processed = processed[1..].trim().to_string();
    }
    if processed.starts_with("@@") {
        processed = processed[2..].trim().to_string();
    }

    if let Some(expr) = processed.strip_prefix("@css:") {
        return css::extract_text(element, expr.trim());
    }
    if let Some(expr) = processed.strip_prefix("@CSS:") {
        return css::extract_text(element, expr.trim());
    }
    if processed.starts_with(':') {
        let expr = processed[1..].trim();
        return expr
            .split("&&")
            .map(|p| css::extract_text(element, p.trim()))
            .collect::<Vec<_>>()
            .join("");
    }

    // 默认当作 CSS 规则
    css::extract_text(element, &processed)
}

/// 从 HTML 元素按规则提取属性
pub fn extract_attr(element: &ElementRef<'_>, rule: &str, attr: &str) -> String {
    if rule.is_empty() {
        return String::new();
    }

    if rule.contains("||") {
        for part in split_top_level(rule, "||") {
            let result = extract_attr(element, part.trim(), attr);
            if !result.is_empty() {
                return result;
            }
        }
        return String::new();
    }

    let mut processed = rule.trim().to_string();
    while processed.starts_with('@') && !processed.starts_with("@@") {
        processed = processed[1..].trim().to_string();
    }

    if let Some(expr) = processed.strip_prefix("@css:") {
        return css::extract_attr(element, expr.trim(), attr);
    }

    css::extract_attr(element, &processed, attr)
}

/// 查询匹配规则的元素列表
pub fn query_all<'a>(html: &'a Html, body: &ElementRef<'a>, rule: &str) -> Vec<ElementRef<'a>> {
    if rule.is_empty() {
        return vec![body.clone()];
    }

    let mut processed = rule.trim().to_string();
    if let Some(expr) = processed.strip_prefix("@css:") {
        processed = expr.trim().to_string();
    }
    if processed.starts_with(':') {
        processed = processed[1..].trim().to_string();
    }

    if let Ok(sel) = Selector::parse(&processed) {
        return html.select(&sel).collect();
    }

    // 智能兜底
    for fallback in [".result-item", ".search-item", ".list-item", "li"] {
        if let Ok(sel) = Selector::parse(fallback) {
            let items: Vec<_> = html.select(&sel).collect();
            if items.len() >= 3 {
                return items;
            }
        }
    }
    vec![]
}

pub fn resolve_url(url: &str, base_url: &str) -> String {
    if url.starts_with("http") {
        return url.to_string();
    }
    let base = base_url.trim_end_matches('/');
    if url.starts_with('/') {
        format!("{base}{url}")
    } else {
        format!("{base}/{url}")
    }
}

fn split_top_level(s: &str, sep: &str) -> Vec<String> {
    let mut parts = Vec::new();
    let mut current = String::new();
    let sep_len = sep.len();
    let mut i = 0;
    let chars: Vec<char> = s.chars().collect();
    while i < chars.len() {
        if i + sep_len <= chars.len() {
            let candidate: String = chars[i..i + sep_len].iter().collect();
            if candidate == sep {
                parts.push(current.clone());
                current.clear();
                i += sep_len;
                continue;
            }
        }
        current.push(chars[i]);
        i += 1;
    }
    parts.push(current);
    parts
}
