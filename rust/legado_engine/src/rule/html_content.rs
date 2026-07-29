use crate::model::book_source::BookSource;
use crate::rule::{engine, js_engine, legado_rule, replace_regex};
use regex::Regex;
use scraper::{Html, Selector};
use std::collections::HashSet;

pub fn parse_html_content(html: &str, source: &BookSource) -> Result<String, String> {
    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let document = Html::parse_document(html);
    let body = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body 元素")?;

    let rule = source.rule_content.trim();
    let mut content = if !rule.is_empty() {
        if js_engine::contains_js_block(rule) {
            if let Some(script) = js_engine::extract_js_block(rule) {
                js_engine::run_html_js(&script, html, js_lib, base)?
            } else {
                String::new()
            }
        } else {
            let legado = legado_rule::extract_text(&body, rule);
            if !legado.is_empty() || legado_rule::is_legado_chain_rule(rule) {
                legado
            } else {
                extract_content_by_rule(&document, &body, rule)
            }
        }
    } else {
        smart_extract_content(&document)
    };

    if let Some(re) = &source.rule_content_replace_regex {
        content = replace_regex::apply_replace_regex(&content, re);
    }

    content = clean_content(&content);
    Ok(content)
}

pub fn extract_next_content_url(
    html: &str,
    source: &BookSource,
    base_url: &str,
    _current_url: &str,
) -> String {
    extract_next_content_urls(html, source, base_url, _current_url)
        .into_iter()
        .next()
        .unwrap_or_default()
}

pub fn extract_next_content_urls(
    html: &str,
    source: &BookSource,
    base_url: &str,
    _current_url: &str,
) -> Vec<String> {
    let rule = source.rule_content_next_url.trim();
    if rule.is_empty() {
        return Vec::new();
    }
    let document = Html::parse_document(html);
    let body = match document.select(&Selector::parse("body").unwrap()).next() {
        Some(b) => b,
        None => return Vec::new(),
    };

    let mut raw_urls = Vec::new();
    if let Some((selector_rule, terminal)) = split_simple_attr_rule(rule) {
        let selector = selector_rule
            .strip_prefix("@css:")
            .or_else(|| selector_rule.strip_prefix("@CSS:"))
            .unwrap_or(selector_rule);
        if let Ok(selector) = Selector::parse(selector.trim()) {
            raw_urls.extend(
                body.select(&selector)
                    .filter_map(|element| element.value().attr(terminal))
                    .map(str::to_string),
            );
        }
    }
    if raw_urls.is_empty() {
        let mut url = engine::extract_attr(&body, rule, "href");
        if url.is_empty() {
            url = engine::extract_text(&body, rule);
        }
        if !url.is_empty() {
            raw_urls.push(url);
        }
    }

    let mut seen = HashSet::new();
    raw_urls
        .into_iter()
        .map(|url| engine::resolve_url(&url, base_url))
        .filter(|url| !url.is_empty() && seen.insert(url.clone()))
        .collect()
}

fn split_simple_attr_rule(rule: &str) -> Option<(&str, &str)> {
    if rule.contains("||") || rule.contains("&&") {
        return None;
    }
    let (selector, terminal) = rule.rsplit_once('@')?;
    if selector.trim().is_empty() || terminal.trim().is_empty() {
        return None;
    }
    Some((selector.trim(), terminal.trim()))
}

fn extract_content_by_rule(document: &Html, body: &scraper::ElementRef<'_>, rule: &str) -> String {
    if rule.contains("||") {
        for part in rule.split("||") {
            let result = extract_content_by_rule(document, body, part.trim());
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

    if js_engine::contains_js_block(&processed) {
        return String::new();
    }

    let elements = engine::query_all(document, body, &processed);
    if let Some(el) = elements.first() {
        return el.text().collect::<String>().trim().to_string();
    }
    engine::extract_text(body, &processed)
}

fn smart_extract_content(document: &Html) -> String {
    for sel in [
        "#content",
        ".chapter-content",
        "#chaptercontent",
        "article#nr",
    ] {
        if let Ok(selector) = Selector::parse(sel) {
            if let Some(el) = document.select(&selector).next() {
                let text = el.text().collect::<String>().trim().to_string();
                if text.len() > 100 {
                    return text;
                }
            }
        }
    }
    String::new()
}

fn clean_content(content: &str) -> String {
    let re_blank = Regex::new(r"\n{3,}").unwrap();
    re_blank.replace_all(content, "\n\n").trim().to_string()
}

#[cfg(test)]
mod next_content_url_tests {
    use super::*;

    #[test]
    fn extracts_all_next_content_urls_in_rule_order() {
        let source = BookSource::from_json(
            r##"{
                "bookSourceUrl":"https://example.com",
                "ruleContent":{"content":"#content","nextContentUrl":".next@href"}
            }"##,
        )
        .unwrap();
        let html = r#"
            <html><body>
              <a class="next" href="/chapter/2">第 2 页</a>
              <a class="next" href="/chapter/3">第 3 页</a>
            </body></html>
        "#;

        assert_eq!(
            extract_next_content_urls(
                html,
                &source,
                "https://example.com/chapter/1",
                "https://example.com/chapter/1",
            ),
            vec![
                "https://example.com/chapter/2",
                "https://example.com/chapter/3",
            ]
        );
    }
}
