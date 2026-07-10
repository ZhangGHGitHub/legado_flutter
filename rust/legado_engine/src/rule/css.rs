use scraper::{ElementRef, Selector};

/// CSS 选择器提取文本，支持 `selector@text` / `selector@href` 终端
pub fn extract_text(element: &ElementRef<'_>, rule: &str) -> String {
    let (selector, terminal) = split_terminal(rule);
    if selector.is_empty() {
        return String::new();
    }

    if let Ok(sel) = Selector::parse(&selector) {
        if let Some(el) = element.select(&sel).next() {
            return match terminal.as_str() {
                "text" | "ownText" | "" => el.text().collect::<String>().trim().to_string(),
                "html" => el.html(),
                "textNodes" => el.text().collect::<String>().trim().to_string(),
                attr if attr == "href" || attr == "src" => {
                    el.value().attr(attr).unwrap_or("").to_string()
                }
                other => {
                    if let Some(attr) = other.strip_prefix('@') {
                        el.value().attr(attr).unwrap_or("").to_string()
                    } else {
                        el.text().collect::<String>().trim().to_string()
                    }
                }
            };
        }
    }
    String::new()
}

/// CSS 选择器提取属性
pub fn extract_attr(element: &ElementRef<'_>, rule: &str, default_attr: &str) -> String {
    let (selector, terminal) = split_terminal(rule);
    let attr = if terminal.is_empty() || terminal == "text" {
        default_attr
    } else if terminal.starts_with('@') {
        &terminal[1..]
    } else {
        &terminal
    };

    if let Ok(sel) = Selector::parse(&selector) {
        if let Some(el) = element.select(&sel).next() {
            return el.value().attr(attr).unwrap_or("").to_string();
        }
    }
    if let Ok(sel) = Selector::parse("a") {
        if let Some(el) = element.select(&sel).next() {
            return el.value().attr(default_attr).unwrap_or("").to_string();
        }
    }
    String::new()
}

fn split_terminal(rule: &str) -> (String, String) {
    let rule = rule.trim();
    if let Some(idx) = rule.rfind('@') {
        let selector = rule[..idx].trim().to_string();
        let terminal = rule[idx + 1..].trim().to_string();
        (selector, terminal)
    } else {
        (rule.to_string(), "text".to_string())
    }
}
