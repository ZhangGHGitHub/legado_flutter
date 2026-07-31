use super::{AppError, BookInfoItem};
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;

/// 获取书籍详情
pub async fn get_book_info(source_json: &str, book_url: &str) -> Result<BookInfoItem, AppError> {
    let source = BookSource::from_json(source_json).map_err(AppError::Parse)?;
    if source.needs_dart_js_for_book_info() {
        return Err(AppError::JsExecution(
            "书源含 JS 规则，需 Dart 引擎".to_string(),
        ));
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }
    http::rate_limit::wait_if_needed(&source.book_source_url)
        .await
        .map_err(AppError::Network)?;

    let body = http::client::fetch_with_source(book_url, "GET", None, "UTF-8", &source.raw_json)
        .await
        .map_err(AppError::Network)?;

    if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
        if source.is_json_api() {
            if let Ok(info) = rule::json_book_info::parse_json_book_info(&data, &source, book_url) {
                if !info.name.is_empty() {
                    let base = http::client::base_url(book_url);
                    return Ok(BookInfoItem {
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
                    });
                }
            }
        }
    }

    let info = rule::html_book_info::parse_html_book_info_at(&body, &source, book_url)
        .map_err(AppError::Parse)?;
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
        } else if info.toc_url.starts_with("http") {
            info.toc_url
        } else {
            http::client::resolve_url(&info.toc_url, book_url)
        },
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn maps_source_json_errors_to_parse_without_changing_text() {
        let error = get_book_info("{", "https://example.com/book")
            .await
            .unwrap_err();

        assert!(matches!(
            error,
            AppError::Parse(ref message) if message.starts_with("书源 JSON 解析失败:")
        ));
    }

    #[tokio::test]
    async fn maps_dart_js_requirement_to_js_execution() {
        let source = serde_json::json!({
            "bookSourceUrl": "https://example.com",
            "ruleBookInfo": { "name": "@js:book.name" }
        })
        .to_string();

        let error = get_book_info(&source, "https://example.com/book")
            .await
            .unwrap_err();

        assert!(matches!(
            error,
            AppError::JsExecution(ref message) if message == "书源含 JS 规则，需 Dart 引擎"
        ));
    }

    #[tokio::test]
    async fn preserves_ssrf_as_network_error() {
        let source = serde_json::json!({
            "bookSourceUrl": "http://127.0.0.1",
            "ruleBookInfo": { "name": "h1" }
        })
        .to_string();

        let error = get_book_info(&source, "http://127.0.0.1/book")
            .await
            .unwrap_err();

        assert!(matches!(
            error,
            AppError::Network(ref message) if message.contains("SSRF")
        ));
    }
}
