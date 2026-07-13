use legado_engine::{get_book_info, get_content, get_toc};
use std::fs; use std::path::PathBuf;

fn tomato() -> String {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources/7497.json");
    let raw = fs::read_to_string(path).unwrap();
    let t = raw.trim_start_matches('\u{feff}');
    let arr: Vec<serde_json::Value> = serde_json::from_str(t).unwrap();
    arr[0].to_string()
}
fn bishu() -> String {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources/7565.json");
    let raw = fs::read_to_string(path).unwrap();
    let t = raw.trim_start_matches('\u{feff}');
    let arr: Vec<serde_json::Value> = serde_json::from_str(t).unwrap();
    arr[0].to_string()
}

#[tokio::test]
#[ignore]
async fn check_shelf_books() {
    // tomato 5946
    let s = tomato();
    let u = "https://novel.cooks.tw/api/novel/detail/5946?lang=zh-CN".to_string();
    let info = get_book_info(s.clone(), u.clone()).await.unwrap();
    let ch = get_toc(s.clone(), info.toc_url.clone()).await.unwrap();
    println!("tomato 5946: name={} n={} url0={}", info.name, ch.len(), ch[0].url);
    let c = get_content(s.clone(), ch[0].url.clone()).await.unwrap();
    println!("  content {} chars", c.len());

    // bishu books
    for url in [
        "http://m.biqukun.org/44/44671/",
        "http://m.biqukun.org/159/159724/",
        "http://m.biqukun.org/156/156995/",
    ] {
        let s = bishu();
        let info = get_book_info(s.clone(), url.to_string()).await.unwrap();
        let toc = if info.toc_url.is_empty() { url.to_string() } else { info.toc_url.clone() };
        let ch = get_toc(s.clone(), toc).await.unwrap();
        println!("bishu {}: name={} n={} url0={}", url, info.name, ch.len(), ch.first().map(|c| c.url.as_str()).unwrap_or(""));
        if let Some(first) = ch.first() {
            let c = get_content(s.clone(), first.url.clone()).await.unwrap();
            println!("  content {} chars preview={:?}", c.len(), &c[..c.len().min(40)]);
        }
    }
}
