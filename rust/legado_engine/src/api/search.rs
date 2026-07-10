use super::SearchItem;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;

/// 执行书源搜索
pub fn search(source_json: &str, keyword: &str) -> Result<Vec<SearchItem>, String> {
    let source = BookSource::from_json(source_json)?;
    if source.rule_search_url.is_empty() {
        return Ok(vec![]);
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }
    http::rate_limit::wait_if_needed(&source.book_source_url)?;

    let cfg = http::client::parse_url_config(&source.rule_search_url, keyword);
    let mut resolved_url = cfg.url.clone();
    if !resolved_url.starts_with("http") {
        resolved_url = http::client::resolve_url(&resolved_url, &source.book_source_url);
    }

    let body = http::client::fetch_with_source(
        &resolved_url,
        &cfg.method,
        cfg.body.as_deref(),
        &cfg.charset,
        &source.raw_json,
    )?;

    // JSON API 书源
    if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
        if source.is_json_api() {
            if let Ok(items) = rule::json_search::parse_json_search(&data, &source) {
                if !items.is_empty() {
                    let base = http::client::base_url(&source.book_source_url);
                    return Ok(items
                        .into_iter()
                        .map(|r| SearchItem {
                            name: r.name,
                            author: r.author,
                            cover_url: rule::engine::resolve_url(&r.cover_url, &base),
                            book_url: rule::engine::resolve_url(&r.book_url, &base),
                            kind: r.kind,
                            note: r.note,
                        })
                        .collect());
                }
            }
        }
    }

    // HTML 书源
    let results = rule::html_search::parse_html_search(&body, &source)?;
    let base = http::client::base_url(&source.book_source_url);
    Ok(results
        .into_iter()
        .map(|r| SearchItem {
            name: r.name,
            author: r.author,
            cover_url: rule::engine::resolve_url(&r.cover_url, &base),
            book_url: rule::engine::resolve_url(&r.book_url, &base),
            kind: r.kind,
            note: r.note,
        })
        .collect())
}
