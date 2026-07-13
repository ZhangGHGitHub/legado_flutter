//! one-off compare Flutter-style toc path
use legado_engine::{get_book_info, get_content, get_toc, search};
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
async fn compare_toc_paths() {
    let source = source();
    let results = search(source.clone(), "斗破".into()).await.unwrap();
    let book = &results[0];
    println!("book {} {}", book.name, book.book_url);
    let info = get_book_info(source.clone(), book.book_url.clone()).await.unwrap();
    println!("tocUrl {}", info.toc_url);

    let via_detail = get_toc(source.clone(), book.book_url.clone()).await.unwrap();
    println!("detail path: n={} url0={}", via_detail.len(), via_detail.first().map(|c| c.url.as_str()).unwrap_or(""));

    // Flutter path: getToc(tocUrl) after getBookInfo
    let via_list = get_toc(source.clone(), info.toc_url.clone()).await.unwrap();
    println!("list path:   n={} url0={}", via_list.len(), via_list.first().map(|c| c.url.as_str()).unwrap_or(""));

    for (label, chs) in [("detail", &via_detail), ("list", &via_list)] {
        if let Some(u) = chs.first() {
            let c = get_content(source.clone(), u.url.clone()).await.unwrap();
            println!("{label} content: {} chars url={}", c.len(), u.url);
        }
    }
}
