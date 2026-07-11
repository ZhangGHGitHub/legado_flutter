use super::ChapterItem;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;
use std::collections::HashSet;

/// 获取目录
pub async fn get_toc(source_json: &str, book_url: &str) -> Result<Vec<ChapterItem>, String> {
    let source = BookSource::from_json(source_json)?;
    if source.needs_dart_js() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }

    let mut fetch_url = book_url.to_string();
    if !source.rule_book_info_toc_url.is_empty() {
        let toc = source.rule_book_info_toc_url.trim();
        if !toc.contains("<js>") {
            fetch_url = if toc.starts_with("http") {
                toc.to_string()
            } else {
                http::client::resolve_url(toc, book_url)
            };
        }
    }

    let mut merged = Vec::new();
    let mut seen = HashSet::new();
    let mut visited_pages = HashSet::new();
    let mut current_url = fetch_url;
    let base_url = http::client::base_url(&current_url);
    let max_pages = 50;

    for _page in 0..max_pages {
        if current_url.is_empty() || visited_pages.contains(&current_url) {
            break;
        }
        visited_pages.insert(current_url.clone());

        http::rate_limit::wait_if_needed(&source.book_source_url).await?;
        let body = http::client::fetch_with_source(
            &current_url,
            "GET",
            None,
            "UTF-8",
            &source.raw_json,
        )
        .await?;

        let batch = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_toc::parse_json_toc(&data, &source)?
                    .into_iter()
                    .map(|c| ChapterItem {
                        title: c.title,
                        url: http::client::resolve_url(&c.url, &base_url),
                    })
                    .collect()
            } else {
                parse_html_toc_items(&body, &source, &base_url)?
            }
        } else {
            parse_html_toc_items(&body, &source, &base_url)?
        };

        let mut added = 0;
        for ch in batch {
            if seen.insert(ch.url.clone()) {
                merged.push(ch);
                added += 1;
            }
        }

        if added == 0 && !merged.is_empty() {
            break;
        }

        let next = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_toc::extract_json_next_url(&data, &source.rule_toc_next_toc_url)
            } else {
                String::new()
            }
        } else {
            rule::html_toc::extract_next_toc_url(&body, &source, &base_url)
        };

        if next.is_empty() {
            break;
        }
        let resolved = http::client::resolve_url(&next, &base_url);
        if visited_pages.contains(&resolved) {
            break;
        }
        current_url = resolved;
    }

    Ok(merged)
}

fn parse_html_toc_items(
    body: &str,
    source: &BookSource,
    base_url: &str,
) -> Result<Vec<ChapterItem>, String> {
    Ok(rule::html_toc::parse_html_toc(body, source)?
        .into_iter()
        .map(|c| ChapterItem {
            title: c.title,
            url: http::client::resolve_url(&c.url, base_url),
        })
        .collect())
}
