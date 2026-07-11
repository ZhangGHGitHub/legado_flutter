use crate::model::book_source::BookSource;
use crate::rule::{engine, js_engine, legado_rule, replace_regex};
use regex::Regex;
use scraper::{Html, Selector};

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
    let rule = source.rule_content_next_url.trim();
    if rule.is_empty() {
        return String::new();
    }
    let document = Html::parse_document(html);
    let body = match document.select(&Selector::parse("body").unwrap()).next() {
        Some(b) => b,
        None => return String::new(),
    };

    let mut url = engine::extract_attr(&body, rule, "href");
    if url.is_empty() {
        url = engine::extract_text(&body, rule);
    }
    if url.is_empty() {
        return String::new();
    }
    engine::resolve_url(&url, base_url)
}

fn extract_content_by_rule(
    document: &Html,
    body: &scraper::ElementRef<'_>,
    rule: &str,
) -> String {
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
    for sel in ["#content", ".chapter-content", "#chaptercontent", "article#nr"] {
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
