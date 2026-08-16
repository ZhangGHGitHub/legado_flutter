//! RSS API — 对齐 Jingshiro model/rss/Rss.kt

use super::AppError;
use crate::rule::rss_parser::{self, RssArticleItem};

fn map_rss_error(message: String) -> AppError {
    if message.starts_with("获取 RSS 失败:") || message.starts_with("获取正文失败:") {
        AppError::Network(message)
    } else {
        AppError::Parse(message)
    }
}

pub(crate) async fn get_rss_articles(
    source_json: &str,
    sort_url: &str,
    sort_name: &str,
    page: i32,
) -> Result<(Vec<RssArticleItem>, Option<String>), AppError> {
    rss_parser::get_articles(source_json, sort_url, sort_name, page)
        .await
        .map_err(map_rss_error)
}

pub(crate) async fn get_rss_content(
    source_json: &str,
    article_link: &str,
) -> Result<String, AppError> {
    rss_parser::get_content(source_json, article_link)
        .await
        .map_err(map_rss_error)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preserves_source_parse_error_text() {
        let message = "RSS 源 JSON 解析失败: unexpected end of input".to_string();

        let error = map_rss_error(message.clone());

        assert!(matches!(error, AppError::Parse(value) if value == message));
    }

    #[test]
    fn maps_article_request_error_to_network_without_changing_text() {
        let message = "获取 RSS 失败: SSRF 拒绝访问内网地址".to_string();

        let error = map_rss_error(message.clone());

        assert!(matches!(error, AppError::Network(value) if value == message));
    }

    #[test]
    fn maps_response_parse_error_to_parse_without_changing_text() {
        let message = "RSS XML 解析失败: mismatched tag".to_string();

        let error = map_rss_error(message.clone());

        assert!(matches!(error, AppError::Parse(value) if value == message));
    }

    #[test]
    fn keeps_parse_error_as_parse_when_text_mentions_network() {
        let message = "RSS XML 解析失败: network element is invalid".to_string();

        let error = map_rss_error(message.clone());

        assert!(matches!(error, AppError::Parse(value) if value == message));
    }
}
