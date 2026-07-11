use super::ChapterItem;
use crate::api::book_info;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;
use std::collections::HashSet;

use crate::rule::js_engine;

/// 获取目录
pub async fn get_toc(source_json: &str, book_url: &str) -> Result<Vec<ChapterItem>, String> {
    let source = BookSource::from_json(source_json)?;
    let _ = js_engine::reset_cache();
    if source.needs_dart_js_for_toc() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }

    let fetch_url = resolve_toc_fetch_url(&source, book_url).await?;
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
                rule::json_toc::parse_json_toc(&data, &source, &current_url)?
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

/// 解析目录页 URL：JSON 书源含 JS tocUrl 时先走 book_info
async fn resolve_toc_fetch_url(source: &BookSource, book_url: &str) -> Result<String, String> {
    let flat_rule = source.rule_book_info_toc_url.trim();
    let obj_has_js = source
        .rule_book_info_obj
        .as_ref()
        .and_then(|o| o.get("tocUrl"))
        .and_then(|v| v.as_str())
        .map(|s| s.contains("<js>"))
        .unwrap_or(false);

    if source.is_json_api() && (flat_rule.contains("<js>") || obj_has_js) {
        let info = book_info::get_book_info(&source.raw_json, book_url).await?;
        if !info.toc_url.is_empty() {
            return Ok(info.toc_url);
        }
    }

    if !flat_rule.is_empty() && !flat_rule.contains("<js>") {
        return Ok(if flat_rule.starts_with("http") {
            flat_rule.to_string()
        } else {
            http::client::resolve_url(flat_rule, book_url)
        });
    }

    Ok(book_url.to_string())
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
