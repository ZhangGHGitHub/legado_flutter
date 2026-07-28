use regex::Regex;
use scraper::{ElementRef, Selector};

/// Legado 链式规则：`class.block_txt2@tag.h2@text##pattern##repl`
pub fn extract_text(element: &ElementRef<'_>, rule: &str) -> String {
    let rule = rule.trim();
    if rule.is_empty() {
        return String::new();
    }
    if !is_legado_chain_rule(rule) {
        return String::new();
    }
    let (body, regex) = split_regex_suffix(rule);
    let segments = parse_segments(&body);
    if segments.is_empty() {
        return String::new();
    }

    let mut current = vec![element.clone()];
    for (idx, seg) in segments.iter().enumerate() {
        let is_last = idx == segments.len() - 1;
        if is_last && seg.is_terminal {
            let mut out = current
                .iter()
                .map(|el| extract_terminal(el, seg))
                .filter(|value| !value.is_empty())
                .collect::<Vec<_>>()
                .join("\n");
            if let Some((pat, rep)) = regex {
                out = apply_regex(&out, &pat, &rep);
            }
            return out;
        }
        current = apply_segment(&current, seg);
        if current.is_empty() {
            return String::new();
        }
    }

    if let Some(el) = current.first() {
        let mut out = el.text().collect::<String>().trim().to_string();
        if let Some((pat, rep)) = regex {
            out = apply_regex(&out, &pat, &rep);
        }
        out
    } else {
        String::new()
    }
}

pub fn extract_attr(element: &ElementRef<'_>, rule: &str, default_attr: &str) -> String {
    let rule = rule.trim();
    if rule.is_empty() {
        return String::new();
    }

    if is_legado_chain_rule(rule) {
        let (body, regex) = split_regex_suffix(rule);
        let segments = parse_segments(&body);
        if !segments.is_empty() {
            let mut current = vec![element.clone()];
            for (idx, seg) in segments.iter().enumerate() {
                let is_last = idx == segments.len() - 1;
                if is_last && seg.is_terminal {
                    let attr = seg
                        .terminal_type
                        .as_deref()
                        .filter(|t| *t != "text" && *t != "html" && *t != "ownText")
                        .unwrap_or(default_attr);
                    let mut out = current[0].value().attr(attr).unwrap_or("").to_string();
                    if out.is_empty() && attr == default_attr {
                        out = extract_terminal(&current[0], seg);
                    }
                    if let Some((pat, rep)) = regex {
                        out = apply_regex(&out, &pat, &rep);
                    }
                    return out;
                }
                current = apply_segment(&current, seg);
                if current.is_empty() {
                    return String::new();
                }
            }
        }
    }

    String::new()
}

pub fn is_legado_chain_rule(rule: &str) -> bool {
    let body = split_regex_suffix(rule).0;
    body.starts_with("class.")
        || body.starts_with("tag.")
        || body.starts_with("text.")
        || body.starts_with("id.")
        || body.starts_with("children.")
        || body.contains("@tag.")
        || body.contains("@class.")
        || body.contains("@text.")
        || body.contains("@text")
        || body.contains("@href")
        || body.contains("@src")
        || body.contains("@html")
        || body.contains("@ownText")
}

fn split_regex_suffix(rule: &str) -> (String, Option<(String, String)>) {
    let Some(hash_idx) = rule.find("##") else {
        return (rule.to_string(), None);
    };
    let body = rule[..hash_idx].to_string();
    let after = &rule[hash_idx + 2..];
    let Some(hash2) = after.find("##") else {
        return (body, None);
    };
    let pat = after[..hash2].to_string();
    let rep = after[hash2 + 2..].to_string();
    (body, Some((pat, rep)))
}

fn apply_regex(text: &str, pattern: &str, replacement: &str) -> String {
    Regex::new(pattern)
        .map(|re| re.replace_all(text, replacement).to_string())
        .unwrap_or_else(|_| text.to_string())
}

#[derive(Debug, Clone)]
struct Segment {
    seg_type: String,
    name: String,
    is_terminal: bool,
    terminal_type: Option<String>,
}

fn parse_segments(rule: &str) -> Vec<Segment> {
    rule.split('@')
        .filter(|s| !s.is_empty())
        .map(parse_one_segment)
        .collect()
}

fn parse_one_segment(raw: &str) -> Segment {
    let raw = raw.trim();
    let terminals = ["text", "href", "src", "html", "ownText", "textNodes", "all"];
    if terminals.contains(&raw) {
        return Segment {
            seg_type: raw.to_string(),
            name: String::new(),
            is_terminal: true,
            terminal_type: Some(raw.to_string()),
        };
    }

    if raw.starts_with("class.") {
        return Segment {
            seg_type: "class".to_string(),
            name: raw[6..].to_string(),
            is_terminal: false,
            terminal_type: None,
        };
    }
    if raw.starts_with("tag.") {
        return Segment {
            seg_type: "tag".to_string(),
            name: raw[4..].to_string(),
            is_terminal: false,
            terminal_type: None,
        };
    }
    if raw.starts_with("text.") {
        return Segment {
            seg_type: "text".to_string(),
            name: raw[5..].to_string(),
            is_terminal: false,
            terminal_type: None,
        };
    }
    if raw.starts_with("id.") {
        return Segment {
            seg_type: "id".to_string(),
            name: raw[3..].to_string(),
            is_terminal: false,
            terminal_type: None,
        };
    }
    if raw.starts_with("children") {
        let name = raw.strip_prefix("children.").unwrap_or("").to_string();
        return Segment {
            seg_type: "children".to_string(),
            name,
            is_terminal: false,
            terminal_type: None,
        };
    }

    Segment {
        seg_type: "css".to_string(),
        name: raw.to_string(),
        is_terminal: false,
        terminal_type: None,
    }
}

fn apply_segment<'a>(parents: &[ElementRef<'a>], seg: &Segment) -> Vec<ElementRef<'a>> {
    let mut result = Vec::new();
    for parent in parents {
        match seg.seg_type.as_str() {
            "class" => {
                let sel = format!(".{}", seg.name);
                let parsed = Selector::parse(&sel);
                if let Ok(s) = parsed {
                    result.extend(parent.select(&s));
                }
            }
            "tag" | "css" => {
                let parsed = Selector::parse(seg.name.as_str());
                if let Ok(s) = parsed {
                    result.extend(parent.select(&s));
                    if result.is_empty() && parent.value().name().eq_ignore_ascii_case(&seg.name) {
                        result.push(parent.clone());
                    }
                }
            }
            "id" => {
                let sel = format!("#{}", seg.name);
                let parsed = Selector::parse(&sel);
                if let Ok(s) = parsed {
                    result.extend(parent.select(&s));
                }
            }
            "text" => {
                if let Ok(s) = Selector::parse("a") {
                    for el in parent.select(&s) {
                        let t = el.text().collect::<String>();
                        if t.contains(&seg.name) {
                            result.push(el);
                        }
                    }
                }
                let all_text = parent.text().collect::<String>();
                if all_text.contains(&seg.name) {
                    result.push(parent.clone());
                }
            }
            "children" => {
                let sel_str = if seg.name.is_empty() {
                    "> *".to_string()
                } else {
                    format!("> {}", seg.name)
                };
                let parsed = Selector::parse(&sel_str);
                if let Ok(s) = parsed {
                    result.extend(parent.select(&s));
                }
            }
            _ => {}
        }
    }
    result
}

fn extract_terminal(el: &ElementRef<'_>, seg: &Segment) -> String {
    match seg.terminal_type.as_deref() {
        Some("text") | Some("all") | None => el.text().collect::<String>().trim().to_string(),
        Some("ownText") => el.text().collect::<String>().trim().to_string(),
        Some("html") => el.html(),
        Some("href") => el.value().attr("href").unwrap_or("").to_string(),
        Some("src") => el.value().attr("src").unwrap_or("").to_string(),
        Some(attr) => el.value().attr(attr).unwrap_or("").to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use scraper::{Html, Selector};

    #[test]
    fn chain_class_tag_text() {
        let html = r#"<div class="block_txt2"><h2>书名</h2></div>"#;
        let doc = Html::parse_fragment(html);
        let root = doc.root_element();
        let out = extract_text(&root, "class.block_txt2@tag.h2@text");
        assert_eq!(out, "书名");
    }

    #[test]
    fn text_label_with_regex_strip() {
        let html = r#"<div><span>作者：天蚕土豆</span></div>"#;
        let doc = Html::parse_fragment(html);
        let body = doc.select(&Selector::parse("div").unwrap()).next().unwrap();
        let out = extract_text(&body, "text.作者@text##.*作者[：:]\\s*##");
        assert_eq!(out, "天蚕土豆");
    }

    #[test]
    fn short_tag_href_on_link_element() {
        let html = r#"<ul class="chapter"><li><a href="/c/1">第一章</a></li></ul>"#;
        let doc = Html::parse_document(html);
        let link = doc
            .select(&Selector::parse("ul.chapter li a").unwrap())
            .next()
            .unwrap();
        assert_eq!(extract_text(&link, "a@text"), "第一章");
        assert_eq!(extract_attr(&link, "a@href", "href"), "/c/1");
    }
}
