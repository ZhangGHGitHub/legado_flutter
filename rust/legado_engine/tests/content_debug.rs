use legado_engine::model::book_source::BookSource;
use legado_engine::{get_book_info, get_content, get_toc};
#[tokio::test]
async fn bishu_ch0_and_source_shape() {
    let mut path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources/7565.json");
    let raw = std::fs::read_to_string(&path).unwrap();
    let t = raw.trim_start_matches('\u{feff}');
    let arr: Vec<serde_json::Value> = serde_json::from_str(t).unwrap();
    let source = arr[0].to_string();
    let bs = BookSource::from_json(&source).unwrap();
    println!(
        "is_json_api={} rule_content_len={} starts_js={}",
        bs.is_json_api(),
        bs.rule_content.len(),
        bs.rule_content.trim_start().starts_with("<js>")
    );
    let url = "http://m.biqukun.org/44/44671/".to_string();
    let info = get_book_info(source.clone(), url.clone()).await.unwrap();
    let toc = if info.toc_url.is_empty() {
        url
    } else {
        info.toc_url
    };
    let ch = get_toc(source.clone(), toc).await.unwrap();
    println!("n={} url0={}", ch.len(), ch[0].url);
    let c = get_content(source.clone(), ch[0].url.clone())
        .await
        .unwrap();
    println!(
        "len={} ph? {} head={:?}",
        c.len(),
        c == "（此章节暂无内容）",
        c.chars().take(30).collect::<String>()
    );
    // also try chapter near 800 if exists
    if ch.len() > 800 {
        let c2 = get_content(source.clone(), ch[800].url.clone())
            .await
            .unwrap();
        println!("ch800 len={} ph? {}", c2.len(), c2 == "（此章节暂无内容）");
    }
}
