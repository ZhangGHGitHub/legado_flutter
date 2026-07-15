use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;
use std::collections::HashSet;

/// 获取章节正文
pub async fn get_content(source_json: &str, chapter_url: &str) -> Result<String, String> {
    let source = BookSource::from_json(source_json)?;
    // 保留 js_cache（目录分页可能写入的密钥等）
    if source.needs_dart_js_for_content() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }

    let base_url = http::client::base_url(chapter_url);
    let mut parts = Vec::new();
    let mut visited = HashSet::new();
    let mut current_url = chapter_url.to_string();
    let max_pages = 20;

    for _ in 0..max_pages {
        if current_url.is_empty() || !visited.insert(current_url.clone()) {
            break;
        }

        http::rate_limit::wait_if_needed(&source.book_source_url).await?;
        let body = http::client::fetch_with_source(
            &current_url,
            "GET",
            None,
            "UTF-8",
            &source.raw_json,
        )
        .await?;

        let chunk = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_content::parse_json_content(&data, &source)?
            } else {
                rule::html_content::parse_html_content(&body, &source)?
            }
        } else {
            rule::html_content::parse_html_content(&body, &source)?
        };

        if !chunk.is_empty() {
            parts.push(chunk);
        }

        let next = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_content::extract_json_next_url(&data, &source.rule_content_next_url)
            } else {
                String::new()
            }
        } else {
            rule::html_content::extract_next_content_url(
                &body,
                &source,
                &base_url,
                &current_url,
            )
        };

        if next.is_empty() {
            break;
        }
        current_url = http::client::resolve_url(&next, &base_url);
    }

    let content = parts.join("\n\n").trim().to_string();
    if content.is_empty() {
        // 勿把解析失败静默成「成功」占位——上层会误缓存、阅读页也无法区分真失败
        Err(format!(
            "正文解析为空（请检查章节 URL 与 ruleContent）: {chapter_url}"
        ))
    } else {
        Ok(content)
    }
}
