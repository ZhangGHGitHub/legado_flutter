use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;
use std::collections::HashSet;
use tokio::task::JoinSet;

const MAX_SEQUENTIAL_CONTENT_PAGES: usize = 100;

#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn get_content(source_json: &str, chapter_url: &str) -> Result<String, String> {
    get_content_with_next_chapter(source_json, chapter_url, None).await
}

#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn get_content_with_next_chapter(
    source_json: &str,
    chapter_url: &str,
    next_chapter_url: Option<&str>,
) -> Result<String, String> {
    let source = BookSource::from_json(source_json)?;
    if source.needs_dart_js_for_content() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }
    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }

    let next_chapter_url = next_chapter_url
        .filter(|url| !url.trim().is_empty())
        .map(|url| http::client::resolve_url(url, chapter_url));
    let mut parts = Vec::new();
    let mut visited = HashSet::from([chapter_url.to_string()]);
    let (first_chunk, next_urls) = fetch_content_page(&source, chapter_url, true).await?;
    if !first_chunk.is_empty() {
        parts.push(first_chunk);
    }

    let next_urls = filter_next_urls(next_urls, next_chapter_url.as_deref(), &visited);
    if next_urls.len() == 1 {
        fetch_sequential_pages(
            &source,
            next_urls[0].clone(),
            next_chapter_url.as_deref(),
            &mut visited,
            &mut parts,
        )
        .await?;
    } else if next_urls.len() > 1 {
        fetch_parallel_pages(&source, next_urls, &mut visited, &mut parts).await?;
    }

    let content = parts.join("\n\n").trim().to_string();
    if content.is_empty() {
        Err(format!(
            "正文解析为空（请检查章节 URL 与 ruleContent）: {chapter_url}"
        ))
    } else {
        Ok(content)
    }
}

async fn fetch_sequential_pages(
    source: &BookSource,
    mut next_url: String,
    next_chapter_url: Option<&str>,
    visited: &mut HashSet<String>,
    parts: &mut Vec<String>,
) -> Result<(), String> {
    let mut followed = 0;
    while !next_url.is_empty()
        && !same_url(next_chapter_url, &next_url)
        && visited.insert(next_url.clone())
    {
        followed += 1;
        if followed > MAX_SEQUENTIAL_CONTENT_PAGES {
            return Err(format!(
                "正文分页超过安全上限 {MAX_SEQUENTIAL_CONTENT_PAGES}: {next_url}"
            ));
        }
        let (chunk, next_urls) = fetch_content_page(source, &next_url, true).await?;
        if !chunk.is_empty() {
            parts.push(chunk);
        }
        next_url = filter_next_urls(next_urls, next_chapter_url, visited)
            .into_iter()
            .next()
            .unwrap_or_default();
    }
    Ok(())
}

async fn fetch_parallel_pages(
    source: &BookSource,
    next_urls: Vec<String>,
    visited: &mut HashSet<String>,
    parts: &mut Vec<String>,
) -> Result<(), String> {
    let urls: Vec<String> = next_urls
        .into_iter()
        .filter(|url| visited.insert(url.clone()))
        .collect();
    let mut tasks = JoinSet::new();
    for (index, url) in urls.iter().cloned().enumerate() {
        let source = source.clone();
        tasks.spawn(async move {
            let (content, _) = fetch_content_page(&source, &url, false).await?;
            Ok::<_, String>((index, content))
        });
    }

    let mut ordered = vec![String::new(); urls.len()];
    while let Some(result) = tasks.join_next().await {
        let (index, content) =
            result.map_err(|error| format!("并发正文分页任务失败: {error}"))??;
        ordered[index] = content;
    }
    parts.extend(ordered.into_iter().filter(|content| !content.is_empty()));
    Ok(())
}

async fn fetch_content_page(
    source: &BookSource,
    url: &str,
    include_next_urls: bool,
) -> Result<(String, Vec<String>), String> {
    http::rate_limit::wait_if_needed(&source.book_source_url).await?;
    let body = http::client::fetch_with_source(url, "GET", None, "UTF-8", &source.raw_json).await?;
    let json = serde_json::from_str::<serde_json::Value>(&body).ok();
    let chunk = match json.as_ref() {
        Some(data) if source.is_json_api() => rule::json_content::parse_json_content(data, source)?,
        _ => rule::html_content::parse_html_content(&body, source)?,
    };
    if !include_next_urls {
        return Ok((chunk, Vec::new()));
    }

    let next_urls = match json.as_ref() {
        Some(data) if source.is_json_api() => {
            rule::json_content::extract_json_next_urls(data, &source.rule_content_next_url)
                .into_iter()
                .map(|next| http::client::resolve_url(&next, url))
                .collect()
        }
        _ => rule::html_content::extract_next_content_urls(&body, source, url, url),
    };
    Ok((chunk, next_urls))
}

fn filter_next_urls(
    urls: Vec<String>,
    next_chapter_url: Option<&str>,
    visited: &HashSet<String>,
) -> Vec<String> {
    let mut seen = HashSet::new();
    urls.into_iter()
        .filter(|url| !url.is_empty())
        .filter(|url| !same_url(next_chapter_url, url))
        .filter(|url| !visited.contains(url))
        .filter(|url| seen.insert(url.clone()))
        .collect()
}

fn same_url(expected: Option<&str>, actual: &str) -> bool {
    expected.is_some_and(|expected| expected == actual)
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::extract::{Path, State};
    use axum::response::Html;
    use axum::routing::get;
    use axum::Router;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::Arc;
    use std::time::Duration;

    #[derive(Clone, Default)]
    struct ServerState {
        in_flight: Arc<AtomicUsize>,
        max_in_flight: Arc<AtomicUsize>,
        page_two_requests: Arc<AtomicUsize>,
    }

    async fn page_handler(
        State(state): State<ServerState>,
        Path(page): Path<String>,
    ) -> Html<String> {
        let active = state.in_flight.fetch_add(1, Ordering::SeqCst) + 1;
        state.max_in_flight.fetch_max(active, Ordering::SeqCst);
        if page == "2" {
            state.page_two_requests.fetch_add(1, Ordering::SeqCst);
            tokio::time::sleep(Duration::from_millis(80)).await;
        } else if page == "3" {
            tokio::time::sleep(Duration::from_millis(10)).await;
        }
        state.in_flight.fetch_sub(1, Ordering::SeqCst);

        let body = match page.as_str() {
            "1" => {
                r#"
                <html><body><div id="content">第一页</div>
                <a class="next" href="/page/2">2</a>
                <a class="next" href="/page/3">3</a></body></html>
            "#
            }
            "2" => r#"<html><body><div id="content">第二页</div></body></html>"#,
            "3" => r#"<html><body><div id="content">第三页</div></body></html>"#,
            "cycle-1" => {
                r#"
                <html><body><div id="content">循环一</div>
                <a class="next" href="/page/cycle-2">next</a></body></html>
            "#
            }
            "cycle-2" => {
                r#"
                <html><body><div id="content">循环二</div>
                <a class="next" href="/page/cycle-1">next</a></body></html>
            "#
            }
            "stop" => {
                r#"
                <html><body><div id="content">本章</div>
                <a class="next" href="/page/2">下一章</a></body></html>
            "#
            }
            _ => r#"<html><body><div id="content">未知</div></body></html>"#,
        };
        Html(body.to_string())
    }

    async fn spawn_server() -> (String, ServerState) {
        let state = ServerState::default();
        let app = Router::new()
            .route("/page/:page", get(page_handler))
            .with_state(state.clone());
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        (format!("http://{address}"), state)
    }

    fn source_json(base_url: &str) -> String {
        serde_json::json!({
            "bookSourceUrl": base_url,
            "ruleContent": {
                "content": "#content",
                "nextContentUrl": ".next@href"
            }
        })
        .to_string()
    }

    #[tokio::test]
    async fn parallel_pages_keep_rule_order() {
        let (base_url, state) = spawn_server().await;
        let content = get_content_with_next_chapter(
            &source_json(&base_url),
            &format!("{base_url}/page/1"),
            None,
        )
        .await
        .unwrap();

        assert_eq!(content, "第一页\n\n第二页\n\n第三页");
        assert!(state.max_in_flight.load(Ordering::SeqCst) >= 2);
    }

    #[tokio::test]
    async fn next_chapter_url_is_not_requested_as_content_page() {
        let (base_url, state) = spawn_server().await;
        let next_chapter = format!("{base_url}/page/2");
        let content = get_content_with_next_chapter(
            &source_json(&base_url),
            &format!("{base_url}/page/stop"),
            Some(&next_chapter),
        )
        .await
        .unwrap();

        assert_eq!(content, "本章");
        assert_eq!(state.page_two_requests.load(Ordering::SeqCst), 0);
    }

    #[tokio::test]
    async fn sequential_cycle_stops_without_duplicate_content() {
        let (base_url, _) = spawn_server().await;
        let content = get_content_with_next_chapter(
            &source_json(&base_url),
            &format!("{base_url}/page/cycle-1"),
            None,
        )
        .await
        .unwrap();

        assert_eq!(content, "循环一\n\n循环二");
    }
}
