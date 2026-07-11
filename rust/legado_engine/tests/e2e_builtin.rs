//! 内置书源端到端测试（需网络）
//! 默认 `cargo test` 跳过；运行：`cargo test --test e2e_builtin -- --ignored --nocapture`

use legado_engine::{get_book_info, get_content, get_toc, search};
use std::fs;
use std::path::PathBuf;

fn asset_json(name: &str) -> String {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources");
    path.push(name);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("读取 {name} 失败: {e}"))
}

fn first_source_json(name: &str) -> String {
    let raw = asset_json(name);
    let trimmed = raw.trim_start_matches('\u{feff}');
    if trimmed.starts_with('[') {
        let arr: Vec<serde_json::Value> = serde_json::from_str(trimmed).expect("书源数组");
        arr.first()
            .expect("书源非空")
            .to_string()
    } else {
        trimmed.to_string()
    }
}

async fn pipeline_bishu() {
    let source = first_source_json("7565.json");
    let results = search(source.clone(), "斗破".to_string())
        .await
        .expect("笔书网搜索");
    assert!(!results.is_empty(), "笔书网搜索无结果");

    let book = &results[0];
    assert!(!book.name.is_empty());
    assert!(!book.book_url.is_empty());
    println!("  笔书网搜索: {} / {}", book.name, book.book_url);

    let info = get_book_info(source.clone(), book.book_url.clone())
        .await
        .expect("笔书网详情");
    assert!(!info.name.is_empty());
    println!("  笔书网详情: {}", info.name);

    let toc_url = if info.toc_url.is_empty() {
        book.book_url.clone()
    } else {
        info.toc_url
    };
    let chapters = get_toc(source.clone(), toc_url)
        .await
        .expect("笔书网目录");
    assert!(!chapters.is_empty(), "笔书网目录为空");
    println!("  笔书网目录: {} 章", chapters.len());
    if let (Some(first), Some(last)) = (chapters.first(), chapters.last()) {
        println!("  笔书网目录序: {} -> {}", first.title, last.title);
    }

    let content = get_content(source, chapters[0].url.clone())
        .await
        .expect("笔书网正文");
    assert!(
        content.len() > 500,
        "笔书网正文过短 ({} 字符): {:?}",
        content.len(),
        &content[..content.len().min(80)]
    );
    println!("  笔书网正文: {} 字符", content.len());
}

async fn pipeline_tomato() {
    let source = first_source_json("7497.json");
    let results = search(source.clone(), "斗罗".to_string())
        .await
        .expect("番茄搜索");
    assert!(!results.is_empty(), "番茄搜索无结果");

    let book = &results[0];
    assert!(!book.name.is_empty());
    println!("  番茄搜索: {} / {}", book.name, book.book_url);

    let info = get_book_info(source.clone(), book.book_url.clone())
        .await
        .expect("番茄详情");
    assert!(!info.name.is_empty());
    assert!(
        info.toc_url.contains("/api/chapter/list/"),
        "番茄 tocUrl 异常: {}",
        info.toc_url
    );
    println!("  番茄详情: {} toc={}", info.name, info.toc_url);

    let chapters = get_toc(source.clone(), book.book_url.clone())
        .await
        .expect("番茄目录");
    assert!(!chapters.is_empty(), "番茄目录为空");
    println!("  番茄目录: {} 章", chapters.len());

    let content = get_content(source, chapters[0].url.clone())
        .await
        .expect("番茄正文");
    assert!(content.len() > 20, "番茄正文过短");
    assert!(!content.contains("<p>"), "番茄正文应已清洗 HTML");
    println!("  番茄正文: {} 字符", content.len());
}

#[tokio::test]
#[ignore = "需要网络，运行: cargo test --test e2e_builtin -- --ignored"]
async fn e2e_bishu_full_pipeline() {
    pipeline_bishu().await;
}

#[tokio::test]
#[ignore = "需要网络，运行: cargo test --test e2e_builtin -- --ignored"]
async fn e2e_tomato_full_pipeline() {
    pipeline_tomato().await;
}
