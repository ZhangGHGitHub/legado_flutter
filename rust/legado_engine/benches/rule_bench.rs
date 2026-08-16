use criterion::{black_box, criterion_group, criterion_main, Criterion};
use legado_engine::model::book_source::BookSource;
use legado_engine::rule::{html_search, html_toc};

const SOURCE: &str = r##"{
    "bookSourceUrl": "http://test.example.com/",
    "ruleSearch": {
        "bookList": ".item",
        "name": ".name@text",
        "author": ".author@text",
        "bookUrl": "a@href"
    },
    "ruleToc": {
        "chapterList": ".chapter-list li",
        "chapterName": "a@text",
        "chapterUrl": "a@href"
    }
}"##;

const SEARCH_HTML: &str = r#"
<html><body>
  <div class="item"><div class="name"><a href="/1">书A</a></div><div class="author">作者A</div></div>
  <div class="item"><div class="name"><a href="/2">书B</a></div><div class="author">作者B</div></div>
  <div class="item"><div class="name"><a href="/3">书C</a></div><div class="author">作者C</div></div>
</body></html>
"#;

fn bench_html_search(c: &mut Criterion) {
    let source = BookSource::from_json(SOURCE).unwrap();
    c.bench_function("html_search_parse", |b| {
        b.iter(|| html_search::parse_html_search(black_box(SEARCH_HTML), black_box(&source)))
    });
}

fn bench_html_toc(c: &mut Criterion) {
    let source = BookSource::from_json(SOURCE).unwrap();
    let mut items = String::new();
    for i in 1..=200 {
        items.push_str(&format!(r#"<li><a href="/c/{i}">第{i}章</a></li>"#));
    }
    let html = format!(r#"<html><body><ul class="chapter-list">{items}</ul></body></html>"#);
    c.bench_function("html_toc_parse_200", |b| {
        b.iter(|| html_toc::parse_html_toc(black_box(&html), black_box(&source)))
    });
}

criterion_group!(benches, bench_html_search, bench_html_toc);
criterion_main!(benches);
