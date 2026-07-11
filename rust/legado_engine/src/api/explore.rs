use super::SearchItem;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;

/// 发现页 / 分类页
pub async fn explore(
    source_json: &str,
    explore_url: &str,
    page: i32,
) -> Result<Vec<SearchItem>, String> {
    let source = BookSource::from_json(source_json)?;
    if source.needs_dart_js_for_explore() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }
    if explore_url.trim().is_empty() {
        return Ok(vec![]);
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }
    http::rate_limit::wait_if_needed(&source.book_source_url).await?;

    let cfg = http::client::parse_url_config_with_page(explore_url, "", page);
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
    )
    .await?;

    let results = rule::html_explore::parse_html_explore(&body, &source)?;
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
