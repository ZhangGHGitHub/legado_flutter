use legado_engine::{get_book_info, get_content, get_toc};
use std::fs; use std::path::PathBuf;

fn source() -> String {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources/7497.json");
    let raw = fs::read_to_string(path).unwrap();
    let t = raw.trim_start_matches('\u{feff}');
    let arr: Vec<serde_json::Value> = serde_json::from_str(t).unwrap();
    arr[0].to_string()
}

#[tokio::test]
#[ignore]
async fn bookshelf_tomato_1749() {
    let source = source();
    let book_url = "https://novel.cooks.tw/api/novel/detail/1749?lang=zh-CN".to_string();
    let info = get_book_info(source.clone(), book_url.clone()).await.unwrap();
    println!("name={} toc={}", info.name, info.toc_url);
    let chapters = get_toc(source.clone(), info.toc_url.clone()).await.unwrap();
    println!("n={} url0={}", chapters.len(), chapters.first().map(|c| c.url.as_str()).unwrap_or(""));
    if let Some(u) = chapters.first() {
        let c = get_content(source.clone(), u.url.clone()).await.unwrap();
        println!("content {} chars preview={:?}", c.len(), &c[..c.len().min(60)]);
    }
    // also try a mid chapter if 1000
    if chapters.len() > 10 {
        let u = &chapters[10];
        let c = get_content(source.clone(), u.url.clone()).await.unwrap();
        println!("ch10 {} chars url={}", c.len(), u.url);
    }
}
