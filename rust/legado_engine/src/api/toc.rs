use super::ChapterItem;
use crate::api::book_info;
use crate::http;
use crate::model::book_source::BookSource;
use crate::rule;
use std::collections::{HashSet, VecDeque};

use crate::rule::js_engine;

/// 获取目录
pub async fn get_toc(source_json: &str, book_url: &str) -> Result<Vec<ChapterItem>, String> {
    let mut source = BookSource::from_json(source_json)?;
    let mut reverse = false;
    let mut list_rule = source.rule_toc_chapter_list.trim().to_string();
    if list_rule.starts_with('-') {
        reverse = true;
        list_rule = list_rule[1..].trim().to_string();
    } else if list_rule.starts_with('+') {
        list_rule = list_rule[1..].trim().to_string();
    }
    source.rule_toc_chapter_list = list_rule;
    // 不清空 js_cache：详情 tocUrl 的 java.ajax 可能已写入 kelexs_key/iv
    if source.needs_dart_js_for_toc() {
        return Err("书源含 JS 规则，需 Dart 引擎".to_string());
    }

    // 对齐 Jingshiro getChapterListAwait：刷新目录前执行 preUpdateJs
    js_engine::run_pre_update_js(&source, book_url);

    if let Some(rate) = &source.concurrent_rate {
        http::rate_limit::configure(&source.book_source_url, rate);
    }

    let fetch_url = resolve_toc_fetch_url(&source, book_url).await?;
    let mut merged = Vec::new();
    let mut seen = HashSet::new();
    let mut visited_pages = HashSet::new();
    let mut current_url = fetch_url;
    let mut pending_urls = VecDeque::new();
    // 直接从已解析的番茄目录 URL 进入时，列表中的 articleid 优先于前一本书残留的全局 cache。
    if let Some(article_id) = extract_tomato_article_id(&current_url) {
        crate::rule::js_cache::put("articleid", &article_id, 0);
    }
    let max_pages = 50;
    let mut last_body = String::new();

    for _page in 0..max_pages {
        if current_url.is_empty() {
            current_url = pending_urls.pop_front().unwrap_or_default();
        }
        if current_url.is_empty() {
            break;
        }
        if visited_pages.contains(&current_url) {
            current_url.clear();
            continue;
        }
        visited_pages.insert(current_url.clone());
        let page_base_url = http::client::base_url(&current_url);

        http::rate_limit::wait_if_needed(&source.book_source_url).await?;
        let body =
            http::client::fetch_with_source(&current_url, "GET", None, "UTF-8", &source.raw_json)
                .await?;
        last_body = body.clone();

        let batch = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                rule::json_toc::parse_json_toc(&data, &source, &current_url)?
                    .into_iter()
                    .map(|c| ChapterItem {
                        title: c.title,
                        url: if c.is_volume {
                            c.url
                        } else {
                            http::client::resolve_url(&c.url, &page_base_url)
                        },
                        is_volume: c.is_volume,
                        is_vip: c.is_vip,
                        is_pay: c.is_pay,
                        tag: c.tag,
                        base_url: c.base_url,
                    })
                    .collect()
            } else {
                parse_html_toc_items(&body, &source, &page_base_url, &current_url)?
            }
        } else {
            parse_html_toc_items(&body, &source, &page_base_url, &current_url)?
        };

        let mut added = 0;
        for ch in batch {
            if seen.insert(ch.url.clone()) {
                merged.push(ch);
                added += 1;
            }
        }

        let next_urls = if let Ok(data) = serde_json::from_str::<serde_json::Value>(&body) {
            if source.is_json_api() {
                let next =
                    rule::json_toc::extract_json_next_url(&data, &source.rule_toc_next_toc_url);
                if next.is_empty() {
                    Vec::new()
                } else {
                    vec![next]
                }
            } else {
                Vec::new()
            }
        } else {
            let book_url_guess = current_url.replace("/chapter/", "/book/");
            rule::html_toc::extract_next_toc_urls_at(&body, &source, &current_url, &book_url_guess)?
        };

        if next_urls.is_empty() {
            current_url = pending_urls.pop_front().unwrap_or_default();
            continue;
        }
        // nextTocUrl 可能是 `url,{json}` AnalyzeUrl 形态
        let (next_url, next_method, next_body) = split_analyze_url(&next_urls[0]);
        let resolved = if next_url.starts_with("http") {
            next_url
        } else {
            http::client::resolve_url(&next_url, &page_base_url)
        };
        if visited_pages.contains(&resolved) {
            break;
        }

        if next_method.eq_ignore_ascii_case("POST") {
            for extra in next_urls.iter().skip(1) {
                let (url, method, _) = split_analyze_url(extra);
                if !method.eq_ignore_ascii_case("POST") {
                    pending_urls.push_back(if url.starts_with("http") {
                        url
                    } else {
                        http::client::resolve_url(&url, &page_base_url)
                    });
                }
            }
            // 分页 Ajax：连续 POST，直到无新增章节或无下一页
            let mut post_url = resolved;
            let mut post_payload = next_body;
            for _ in 0..max_pages {
                if !visited_pages.insert(post_url.clone()) {
                    break;
                }
                http::rate_limit::wait_if_needed(&source.book_source_url).await?;
                let post_resp = http::client::fetch_with_source(
                    &post_url,
                    "POST",
                    post_payload.as_deref(),
                    "UTF-8",
                    &source.raw_json,
                )
                .await?;
                last_body = post_resp.clone();
                let post_batch = parse_html_toc_items(
                    &post_resp,
                    &source,
                    &http::client::base_url(&post_url),
                    &post_url,
                )?;
                let mut added = 0;
                for ch in post_batch {
                    if seen.insert(ch.url.clone()) {
                        merged.push(ch);
                        added += 1;
                    }
                }
                if added == 0 {
                    break;
                }
                let book_url_guess = book_url.replace("/chapter/", "/book/");
                let more = rule::html_toc::extract_next_toc_url_at(
                    &post_resp,
                    &source,
                    &post_url,
                    &book_url_guess,
                );
                if more.is_empty() {
                    break;
                }
                let (u, m, b) = split_analyze_url(&more);
                if !m.eq_ignore_ascii_case("POST") {
                    current_url = if u.starts_with("http") {
                        u
                    } else {
                        http::client::resolve_url(&u, &page_base_url)
                    };
                    break;
                }
                post_url = if u.starts_with("http") {
                    u
                } else {
                    http::client::resolve_url(&u, &page_base_url)
                };
                post_payload = b;
            }
            // POST 链结束后退出外层；若切回 GET 则由外层继续
            continue;
        }
        current_url = resolved;
        for extra in next_urls.iter().skip(1) {
            let (url, method, _) = split_analyze_url(extra);
            if !method.eq_ignore_ascii_case("POST") {
                pending_urls.push_back(if url.starts_with("http") {
                    url
                } else {
                    http::client::resolve_url(&url, &page_base_url)
                });
            }
        }
    }

    if merged.is_empty() {
        if let Some(msg) = upstream_toc_failure_message(&last_body) {
            return Err(msg);
        }
    }

    if !reverse {
        merged.reverse();
    }
    Ok(merged)
}

/// 站点返回错误页 / 明文异常时，避免静默「目录 0 条」
fn upstream_toc_failure_message(body: &str) -> Option<String> {
    let t = body.trim();
    if t.is_empty() {
        return Some("目录页为空响应".to_string());
    }
    if t.contains("数据库")
        || t.contains("SQLSTATE")
        || t.contains("Too many connections")
        || t.contains("连接失败")
    {
        let head: String = t.chars().take(160).collect();
        return Some(format!("目录页站点异常: {head}"));
    }
    if t.len() < 120 && !t.contains('<') && !t.starts_with('{') && !t.starts_with('[') {
        let head: String = t.chars().take(160).collect();
        return Some(format!("目录页异常文本: {head}"));
    }
    None
}

/// 拆分 `https://host/path,{"method":"POST","body":"..."}`（Legado AnalyzeUrl）
fn split_analyze_url(raw: &str) -> (String, String, Option<String>) {
    let raw = raw.trim();
    if let Some(comma) = raw.find(",{") {
        let url = raw[..comma].trim().to_string();
        if let Ok(cfg) = serde_json::from_str::<serde_json::Value>(&raw[comma + 1..]) {
            let method = cfg
                .get("method")
                .and_then(|v| v.as_str())
                .unwrap_or("GET")
                .to_string();
            let body = cfg
                .get("body")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string());
            return (url, method, body);
        }
    }
    (raw.to_string(), "GET".to_string(), None)
}

/// 解析目录页 URL：支持 ruleBookInfo.tocUrl 为 `<js>`（可乐小说：/book/→/chapter/）
async fn resolve_toc_fetch_url(source: &BookSource, book_url: &str) -> Result<String, String> {
    // 调用方（校验/调试/getChapters）常已传入详情解析后的目录 URL。
    // 若再以空 result 重跑 tocUrl JS，番茄源会丢失 articleid → `/api/chapter/list/?lang=`。
    if is_already_resolved_toc_url(book_url) {
        return Ok(book_url.to_string());
    }

    let flat_rule = source.rule_book_info_toc_url.trim();
    let obj_toc = source
        .rule_book_info_obj
        .as_ref()
        .and_then(|o| o.get("tocUrl"))
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let toc_rule = if flat_rule.is_empty() {
        obj_toc
    } else {
        flat_rule
    };

    if js_engine::contains_js_block(toc_rule) {
        if let Some(script) = js_engine::extract_js_block(toc_rule) {
            // tocUrl JS 会 java.ajax(book.bookUrl) 抽 AES 密钥，须用详情页而非目录页
            let book_for_ajax = book_url
                .replace("/chapter/", "/book/")
                .replace("/read/", "/book/");
            // 尽量把详情 JSON 传给 tocUrl JS（番茄：J(result).data.articleid）
            let result_json = toc_js_result_payload(book_url);
            if let Ok(out) = js_engine::run_with_result_opts(
                &script,
                &result_json,
                &source.js_lib,
                book_url,
                Some(&book_for_ajax),
            ) {
                let out = out.trim().to_string();
                if is_usable_toc_url(&out) {
                    return Ok(if out.starts_with("http") {
                        out
                    } else {
                        http::client::resolve_url(&out, book_url)
                    });
                }
            }
        }
    }

    if source.is_json_api() && (flat_rule.contains("<js>") || obj_toc.contains("<js>")) {
        let info = book_info::get_book_info(&source.raw_json, book_url).await?;
        if is_usable_toc_url(&info.toc_url) {
            return Ok(info.toc_url);
        }
    }

    if !toc_rule.is_empty() && !js_engine::contains_js_block(toc_rule) {
        return Ok(if toc_rule.starts_with("http") {
            toc_rule.to_string()
        } else {
            http::client::resolve_url(toc_rule, book_url)
        });
    }

    Ok(book_url.to_string())
}

/// 详情/调试已解析出的目录页（勿再跑 tocUrl JS）
fn is_already_resolved_toc_url(url: &str) -> bool {
    let u = url.to_ascii_lowercase();
    // 番茄 JSON：/api/chapter/list/{id}
    if u.contains("/api/chapter/list/") {
        return u
            .split("/api/chapter/list/")
            .nth(1)
            .map(|rest| rest.chars().next().is_some_and(|c| c.is_ascii_digit()))
            .unwrap_or(false);
    }
    // 可乐等：/chapter/{bookId}（非 /book/）
    if u.contains("/chapter/") && !u.contains("/book/") {
        return true;
    }
    false
}

fn is_usable_toc_url(url: &str) -> bool {
    let t = url.trim();
    if t.is_empty() || t == "null" || t == "undefined" {
        return false;
    }
    // 拒绝空 id：.../list/?lang= 或 .../list/
    if t.contains("/list/?") || t.ends_with("/list/") || t.contains("/list/?lang") {
        return false;
    }
    true
}

/// 无详情 body 时，从 detail URL 合成最小 JSON，供 tocUrl JS 取 articleid
fn toc_js_result_payload(book_url: &str) -> String {
    if let Some(id) = extract_tomato_article_id(book_url) {
        return format!(r#"{{"data":{{"articleid":"{id}"}}}}"#);
    }
    String::new()
}

fn extract_tomato_article_id(url: &str) -> Option<String> {
    // .../api/novel/detail/12345?... 或 .../api/chapter/list/12345?...
    for marker in ["/api/novel/detail/", "/api/chapter/list/"] {
        if let Some(pos) = url.find(marker) {
            let rest = &url[pos + marker.len()..];
            let id: String = rest.chars().take_while(|c| c.is_ascii_digit()).collect();
            if !id.is_empty() {
                return Some(id);
            }
        }
    }
    None
}

fn parse_html_toc_items(
    body: &str,
    source: &BookSource,
    base_url: &str,
    page_url: &str,
) -> Result<Vec<ChapterItem>, String> {
    Ok(rule::html_toc::parse_html_toc_at(body, source, page_url)?
        .into_iter()
        .map(|c| ChapterItem {
            title: c.title,
            url: if c.is_volume {
                c.url
            } else if c.url.starts_with("http") {
                c.url
            } else {
                http::client::resolve_url(&c.url, base_url)
            },
            is_volume: c.is_volume,
            is_vip: c.is_vip,
            is_pay: c.is_pay,
            tag: c.tag,
            base_url: c.base_url,
        })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn upstream_sql_error_detected() {
        let msg = upstream_toc_failure_message(
            "数据库连接失败:SQLSTATE[08004] [1040] Too many connections",
        );
        assert!(msg.unwrap().contains("站点异常"));
    }

    #[test]
    fn normal_html_not_flagged_as_upstream_error() {
        assert!(upstream_toc_failure_message(
            r#"<html><body><ul class="chapList chapListBody"><li><a href="/r/1">一</a></li></ul></body></html>"#
        )
        .is_none());
    }
}

#[cfg(test)]
mod tomato_toc_resolve_tests {
    use super::*;
    use crate::rule::js_engine;

    fn load_7497() -> BookSource {
        let raw = include_str!("../../../../assets/builtin_sources/7497.json");
        let json = raw.trim_start_matches('\u{feff}');
        if json.starts_with('[') {
            let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
            BookSource::from_json(&arr[0].to_string()).unwrap()
        } else {
            BookSource::from_json(json).unwrap()
        }
    }

    #[tokio::test]
    async fn already_resolved_list_url_not_rewritten_to_empty_id() {
        let source = load_7497();
        let list_url = "https://novel.cooks.tw/api/chapter/list/81571?lang=zh-CN";
        let out = resolve_toc_fetch_url(&source, list_url).await.unwrap();
        assert!(
            out.contains("/api/chapter/list/81571"),
            "已解析目录 URL 不应被空 result 重写，got {out}"
        );
        assert!(!out.contains("/list/?"), "got {out}");
    }

    #[tokio::test]
    async fn detail_url_resolves_via_toc_js() {
        let source = load_7497();
        let detail = "https://novel.cooks.tw/api/novel/detail/81571?lang=zh-CN";
        let out = resolve_toc_fetch_url(&source, detail).await.unwrap();
        assert!(
            out.contains("/api/chapter/list/81571"),
            "详情 URL 应解析出目录，got {out}"
        );
    }

    #[test]
    fn toc_js_empty_result_on_list_url_loses_id() {
        // 记录 JS 本身在空 result + list baseUrl 时会丢 id；resolve 层须短路
        let source = load_7497();
        let toc_rule = source
            .rule_book_info_obj
            .as_ref()
            .unwrap()
            .get("tocUrl")
            .unwrap()
            .as_str()
            .unwrap();
        let script = js_engine::extract_js_block(toc_rule).unwrap();
        let list_url = "https://novel.cooks.tw/api/chapter/list/81571?lang=zh-CN";
        let out =
            js_engine::run_with_result_opts(&script, "", &source.js_lib, list_url, Some(list_url))
                .unwrap_or_default();
        assert!(
            out.contains("/list/?") || !out.contains("81571"),
            "期望空 result 在 list URL 上无法得到正确 id，got {out}"
        );
    }
}

#[cfg(test)]
mod http_fixture_tests {
    use super::*;
    use crate::api::content;
    use crate::http::client;
    use std::io::{Read, Write};
    use std::net::{TcpListener, TcpStream};
    use std::sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    };
    use std::thread;
    use std::time::Duration;

    struct FixtureServer {
        base_url: String,
        stop: Arc<AtomicBool>,
    }

    impl FixtureServer {
        fn start() -> Self {
            let listener = TcpListener::bind("127.0.0.1:0").unwrap();
            listener.set_nonblocking(true).unwrap();
            let port = listener.local_addr().unwrap().port();
            let stop = Arc::new(AtomicBool::new(false));
            let thread_stop = Arc::clone(&stop);

            thread::spawn(move || {
                while !thread_stop.load(Ordering::Relaxed) {
                    match listener.accept() {
                        Ok((stream, _)) => {
                            // reqwest 可能分片发送请求头；每个连接独立处理，避免一个慢连接阻塞后续请求。
                            thread::spawn(|| handle_request(stream));
                        }
                        Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                            thread::sleep(Duration::from_millis(1));
                        }
                        Err(_) => thread::sleep(Duration::from_millis(1)),
                    }
                }
            });

            Self {
                base_url: format!("http://127.0.0.1:{port}"),
                stop,
            }
        }

        fn source_json(&self) -> String {
            serde_json::json!({
                "bookSourceUrl": self.base_url,
                "ruleToc": {
                    "chapterList": ".chapters li",
                    "chapterName": "a@text",
                    "chapterUrl": "a@href",
                    "nextTocUrl": "a.next@href"
                },
                "ruleContent": {
                    "content": "#content@text",
                    "nextContentUrl": "a.next@href"
                }
            })
            .to_string()
        }

        fn module2_source_json(&self, chapter_list: &str) -> String {
            serde_json::json!({
                "bookSourceUrl": self.base_url,
                "bookSourceName": "Module 2 TOC fixture",
                "ruleToc": {
                    "chapterList": chapter_list,
                    "chapterName": "a@text",
                    "chapterUrl": "a@href",
                    "isVolume": ".is-volume@text",
                    "nextTocUrl": "a.next@href"
                }
            })
            .to_string()
        }

        fn json_source_json(&self) -> String {
            serde_json::json!({
                "bookSourceUrl": self.base_url,
                "ruleToc": {
                    "chapterList": "$.data",
                    "chapterName": "$.chaptername",
                    "chapterUrl": "$.url",
                    "nextTocUrl": "$.next"
                },
                "ruleContent": {
                    "content": "$.data.content",
                    "nextContentUrl": "$.next"
                }
            })
            .to_string()
        }

        fn url(&self, path: &str) -> String {
            format!("{}{}", self.base_url, path)
        }
    }

    impl Drop for FixtureServer {
        fn drop(&mut self) {
            self.stop.store(true, Ordering::Relaxed);
        }
    }

    fn handle_request(mut stream: TcpStream) {
        let _ = stream.set_read_timeout(Some(Duration::from_secs(2)));
        let _ = stream.set_write_timeout(Some(Duration::from_secs(2)));
        let mut request = Vec::with_capacity(4096);
        let mut chunk = [0_u8; 1024];
        while !request.windows(4).any(|window| window == b"\r\n\r\n") {
            match stream.read(&mut chunk) {
                Ok(0) => break,
                Ok(read) => request.extend_from_slice(&chunk[..read]),
                Err(e)
                    if matches!(
                        e.kind(),
                        std::io::ErrorKind::Interrupted | std::io::ErrorKind::WouldBlock
                    ) =>
                {
                    continue
                }
                Err(_) => return,
            }
            if request.len() > 64 * 1024 {
                return;
            }
        }
        let line = String::from_utf8_lossy(&request);
        let path = line
            .lines()
            .next()
            .and_then(|l| l.split_whitespace().nth(1))
            .unwrap_or("/");

        let (status, body) = match path {
            "/toc" => (
                "200 OK",
                r#"<ul class="chapters"><li><a href="/c/1">第一章</a></li><li><a href="/c/2">第二章</a></li></ul><a class="next" href="/toc?page=2">下一页</a>"#
                    .to_string(),
            ),
            "/toc?page=2" => (
                "200 OK",
                r#"<ul class="chapters"><li><a href="/c/3">第三章</a></li><li><a href="/c/4">第四章</a></li></ul>"#
                    .to_string(),
            ),
            "/module2/toc" => ("200 OK", module2_fixture("toc_page1.html")),
            "/module2/toc?page=2" => ("200 OK", module2_fixture("toc_page2.html")),
            "/module2/toc/plus" => ("200 OK", module2_fixture("toc_plus.html")),
            "/module2/toc/multi" => ("200 OK", module2_fixture("toc_multi.html")),
            "/module2/toc/multi-2" => ("200 OK", module2_fixture("toc_multi2.html")),
            "/module2/toc/multi-3" => ("200 OK", module2_fixture("toc_multi3.html")),
            "/module2/toc/cycle" => ("200 OK", module2_fixture("toc_cycle.html")),
            "/content/1" => (
                "200 OK",
                r#"<div id="content">第一段正文</div><a class="next" href="/content/2">下一页</a>"#
                    .to_string(),
            ),
            "/content/2" => (
                "200 OK",
                r#"<div id="content">第二段正文</div>"#.to_string(),
            ),
            "/json/toc" => (
                "200 OK",
                serde_json::json!({
                    "data": [
                        {"chaptername": "JSON 第一章", "url": "/json/c/1"},
                        {"chaptername": "JSON 第二章", "url": "/json/c/2"}
                    ],
                    "next": "/json/toc?page=2"
                })
                .to_string(),
            ),
            "/json/toc?page=2" => (
                "200 OK",
                serde_json::json!({
                    "data": [
                        {"chaptername": "JSON 第三章", "url": "/json/c/3"}
                    ]
                })
                .to_string(),
            ),
            "/json/content/1" => (
                "200 OK",
                serde_json::json!({
                    "data": {"content": "JSON 第一段正文"},
                    "next": "/json/content/2"
                })
                .to_string(),
            ),
            "/json/content/2" => (
                "200 OK",
                serde_json::json!({
                    "data": {"content": "JSON 第二段正文"}
                })
                .to_string(),
            ),
            "/empty" => ("200 OK", String::new()),
            "/status/503" => ("503 Service Unavailable", "站点维护".to_string()),
            "/large" => (
                "200 OK",
                "x".repeat(client::MAX_RESPONSE_BYTES + 1),
            ),
            _ => ("404 Not Found", "not found".to_string()),
        };

        let response = format!(
            "HTTP/1.1 {status}\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            body.len(), body
        );
        let _ = stream.write_all(response.as_bytes());
        let _ = stream.flush();
    }

    fn module2_fixture(name: &str) -> String {
        let mut path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        path.push("../../test/fixtures/rules/module2");
        path.push(name);
        std::fs::read_to_string(path).expect("模块 2 目录 fixture")
    }

    #[tokio::test]
    async fn get_toc_fixture_covers_html_pagination_and_empty_error() {
        let fixture = FixtureServer::start();
        let source = fixture.source_json();
        let chapters = get_toc(&source, &fixture.url("/toc")).await.unwrap();

        assert_eq!(chapters.len(), 4);
        assert_eq!(chapters[0].title, "第四章");
        assert!(chapters[3].url.ends_with("/c/1"));

        let error = get_toc(&source, &fixture.url("/empty"))
            .await
            .expect_err("空目录响应必须返回诊断错误");
        assert!(error.contains("为空响应"), "got {error}");

        let recovered = get_toc(&source, &fixture.url("/toc")).await.unwrap();
        assert_eq!(recovered.len(), 4);
    }

    #[tokio::test]
    async fn get_content_fixture_covers_pagination_status_and_size_errors() {
        let fixture = FixtureServer::start();
        let source = fixture.source_json();
        let content_text = content::get_content(&source, &fixture.url("/content/1"))
            .await
            .unwrap();
        assert!(content_text.contains("第一段正文"));
        assert!(content_text.contains("第二段正文"));

        let status_error = content::get_content(&source, &fixture.url("/status/503"))
            .await
            .expect_err("非 2xx 必须返回 HTTP 诊断错误");
        assert!(status_error.contains("HTTP 请求失败"), "got {status_error}");

        let size_error =
            client::fetch_with_source(&fixture.url("/large"), "GET", None, "UTF-8", &source)
                .await
                .expect_err("超大响应必须被拒绝");
        assert!(size_error.contains("响应过大"), "got {size_error}");
    }

    #[tokio::test]
    async fn json_fixtures_cover_toc_and_content_pagination() {
        let fixture = FixtureServer::start();
        let source = fixture.json_source_json();

        let chapters = get_toc(&source, &fixture.url("/json/toc")).await.unwrap();
        assert_eq!(chapters.len(), 3);
        assert_eq!(chapters[0].title, "JSON 第三章");
        assert!(chapters[2].url.ends_with("/json/c/1"));

        let content_text = content::get_content(&source, &fixture.url("/json/content/1"))
            .await
            .unwrap();
        assert!(content_text.contains("JSON 第一段正文"));
        assert!(content_text.contains("JSON 第二段正文"));
    }

    #[tokio::test]
    async fn module2_default_order_volume_fallback_and_plus_prefix_match_original() {
        let fixture = FixtureServer::start();
        let source = fixture.module2_source_json(".chapters li");
        let toc_url = fixture.url("/module2/toc");
        let chapters = get_toc(&source, &toc_url).await.unwrap();

        assert_eq!(chapters.len(), 3);
        assert_eq!(chapters[0].title, "第一章");
        assert_eq!(chapters[1].title, "卷一");
        assert_eq!(chapters[1].url, "卷一1");
        assert_eq!(chapters[2].title, "第二章");

        let plus_source = fixture.module2_source_json("+.chapters li");
        let plus_url = fixture.url("/module2/toc/plus");
        let plus = get_toc(&plus_source, &plus_url).await.unwrap();
        assert_eq!(plus.len(), 1);
        assert_eq!(plus[0].title, "加号规则章节");
    }

    #[tokio::test]
    async fn module2_multiple_next_toc_urls_are_all_followed() {
        let fixture = FixtureServer::start();
        let source = fixture.module2_source_json(".chapters li");
        let toc_url = fixture.url("/module2/toc/multi");
        let chapters = get_toc(&source, &toc_url).await.unwrap();

        assert_eq!(chapters.len(), 3);
        assert!(chapters.iter().any(|chapter| chapter.title == "第二页"));
        assert!(chapters.iter().any(|chapter| chapter.title == "第三页"));
    }

    #[tokio::test]
    async fn module2_cyclic_next_toc_url_terminates() {
        let fixture = FixtureServer::start();
        let source = fixture.module2_source_json(".chapters li");
        let toc_url = fixture.url("/module2/toc/cycle");
        let chapters = get_toc(&source, &toc_url).await.unwrap();

        assert_eq!(chapters.len(), 1);
        assert_eq!(chapters[0].title, "循环章节");
    }
}
