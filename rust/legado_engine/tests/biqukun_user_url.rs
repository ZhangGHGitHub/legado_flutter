//! 笔书网 m.biqukun.org 正文：JS 规则 + br 交错文本 + 分页

use legado_engine::get_content;
use legado_engine::http;
use legado_engine::model::book_source::BookSource;
use legado_engine::rule::{html_content, js_engine};

fn load_7565() -> String {
    let mut path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources/7565.json");
    let raw = std::fs::read_to_string(&path).unwrap();
    let t = raw.trim_start_matches('\u{feff}');
    let arr: Vec<serde_json::Value> = serde_json::from_str(t).unwrap();
    arr[0].to_string()
}

fn fixture_html() -> String {
    let mut path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../test/fixtures/js/7565_content_br.html");
    std::fs::read_to_string(&path).expect("fixture")
}

#[test]
fn biqukun_offline_br_content_not_empty() {
    let source = load_7565();
    let bs = BookSource::from_json(&source).unwrap();
    let body = fixture_html();
    let parsed = html_content::parse_html_content(&body, &bs).unwrap();
    assert!(
        parsed.len() > 40,
        "br 交错正文不应被「本章未完」整行误杀: len={} content={parsed}",
        parsed.len()
    );
    assert!(
        parsed.contains("钱龙湾") || parsed.contains("大奔") || parsed.contains("秦天命"),
        "应含正文片段: {parsed}"
    );
    assert!(!parsed.contains("本章未完"));
}

#[tokio::test]
async fn fetch_user_chapter_and_parse() {
    let source = load_7565();
    let url = "http://m.biqukun.org/156/156995/50438259.html";
    let bs = BookSource::from_json(&source).unwrap();

    let body = match http::client::fetch_with_source(url, "GET", None, "UTF-8", &source).await {
        Ok(b) => b,
        Err(e) => {
            eprintln!("skip live fetch: {e}");
            return;
        }
    };
    if !body.contains("id=\"nr\"") {
        eprintln!("skip: page has no article#nr (site down?)");
        return;
    }

    let script = js_engine::extract_js_block(&bs.rule_content).expect("js block");
    let js_out =
        js_engine::run_html_js(&script, &body, &bs.js_lib, &bs.book_source_url).expect("js run");
    assert!(
        js_out.len() > 50,
        "live JS content empty: len={} next_hint",
        js_out.len()
    );

    let content = get_content(source, url.to_string())
        .await
        .expect("get_content");
    assert!(
        content.len() > 50,
        "get_content too short: {}",
        content.len()
    );
    println!(
        "ok len={} head={:?}",
        content.len(),
        content.chars().take(40).collect::<String>()
    );
}
