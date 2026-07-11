use super::BookInfoItem;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;

/// 获取书籍详情
pub async fn get_book_info(source_json: &str, book_url: &str) -> Result<BookInfoItem, String> {
    let source = BookSource::from_json(source_json)?;
    if source.needs_dart_js_for_book_info() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }
    http::rate_limit::wait_if_needed(&source.book_source_url).await?;

    let body = http::client::fetch_with_source(
        book_url,
        "GET",
        None,
        "UTF-8",
        &source.raw_json,
    )
    .await?;

    let info = rule::html_book_info::parse_html_book_info(&body, &source)?;
    let base = http::client::base_url(book_url);
    Ok(BookInfoItem {
        name: info.name,
        author: info.author,
        cover_url: rule::engine::resolve_url(&info.cover_url, &base),
        intro: info.intro,
        kind: info.kind,
        last_chapter: info.last_chapter,
        toc_url: if info.toc_url.is_empty() {
            book_url.to_string()
        } else {
            http::client::resolve_url(&info.toc_url, &base)
        },
    })
}
