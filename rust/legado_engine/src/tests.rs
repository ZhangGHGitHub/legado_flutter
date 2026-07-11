#[cfg(test)]
mod engine_tests {
    use crate::model::book_source::BookSource;
    use crate::rule::{html_book_info, html_content, html_search, html_toc};

    const FIXTURE_SOURCE: &str = r##"{
        "bookSourceUrl": "http://test.example.com/",
        "bookSourceName": "测试书源",
        "searchUrl": "http://test.example.com/search?key={{key}}",
        "ruleSearch": {
            "bookList": ".item",
            "name": ".name@text",
            "author": ".author@text",
            "bookUrl": "a@href",
            "coverUrl": "img@src",
            "kind": ".kind@text"
        },
        "ruleBookInfo": {
            "name": "h1@text",
            "author": ".author@text",
            "coverUrl": "img.cover@src",
            "intro": ".intro@text",
            "kind": ".kind@text",
            "lastChapter": ".latest@text",
            "tocUrl": "a.read@href"
        },
        "ruleToc": {
            "chapterList": ".chapter-list li",
            "chapterName": "a@text",
            "chapterUrl": "a@href"
        },
        "ruleContent": {
            "content": "#content@text"
        },
        "ruleExplore": {
            "bookList": ".item",
            "name": ".name@text",
            "author": ".author@text",
            "bookUrl": "a@href"
        }
    }"##;

    const SEARCH_HTML: &str = r#"
    <html><body>
      <div class="item">
        <div class="name"><a href="/book/1">斗破苍穹</a></div>
        <div class="author">天蚕土豆</div>
        <div class="kind">玄幻</div>
        <img src="/cover/1.jpg"/>
      </div>
      <div class="item">
        <div class="name"><a href="/book/2">完美世界</a></div>
        <div class="author">辰东</div>
        <div class="kind">玄幻</div>
        <img src="/cover/2.jpg"/>
      </div>
    </body></html>
    "#;

    const BOOK_INFO_HTML: &str = r#"
    <html><body>
      <h1>斗破苍穹</h1>
      <div class="author">作者：天蚕土豆</div>
      <div class="kind">分类：玄幻</div>
      <div class="intro">这是一个测试简介。</div>
      <div class="latest">最新：第100章</div>
      <img class="cover" src="/cover/1.jpg"/>
      <a class="read" href="/book/1/toc">开始阅读</a>
    </body></html>
    "#;

    const TOC_HTML: &str = r#"
    <html><body>
      <ul class="chapter-list">
        <li><a href="/book/1/1">第一章</a></li>
        <li><a href="/book/1/2">第二章</a></li>
        <li><a href="/book/1/3">第三章</a></li>
      </ul>
    </body></html>
    "#;

    const CONTENT_HTML: &str = r#"
    <html><body>
      <div id="content">正文第一段。

正文第二段。</div>
    </body></html>
    "#;

    fn fixture_source() -> BookSource {
        BookSource::from_json(FIXTURE_SOURCE).expect("fixture source")
    }

    #[test]
    fn parse_html_search_returns_books() {
        let source = fixture_source();
        let results = html_search::parse_html_search(SEARCH_HTML, &source).unwrap();
        assert_eq!(results.len(), 2);
        assert_eq!(results[0].name, "斗破苍穹");
        assert_eq!(results[0].author, "天蚕土豆");
        assert_eq!(results[0].book_url, "/book/1");
    }

    #[test]
    fn parse_html_book_info_extracts_fields() {
        let source = fixture_source();
        let info = html_book_info::parse_html_book_info(BOOK_INFO_HTML, &source).unwrap();
        assert_eq!(info.name, "斗破苍穹");
        assert_eq!(info.author, "作者：天蚕土豆");
        assert_eq!(info.intro, "这是一个测试简介。");
        assert_eq!(info.toc_url, "/book/1/toc");
    }

    #[test]
    fn parse_html_toc_returns_chapters() {
        let source = fixture_source();
        let chapters = html_toc::parse_html_toc(TOC_HTML, &source).unwrap();
        assert_eq!(chapters.len(), 3);
        assert_eq!(chapters[0].title, "第一章");
        assert_eq!(chapters[0].url, "/book/1/1");
    }

    #[test]
    fn parse_html_content_extracts_text() {
        let source = fixture_source();
        let content = html_content::parse_html_content(CONTENT_HTML, &source).unwrap();
        assert!(content.contains("正文第一段"));
        assert!(content.contains("正文第二段"));
    }

    #[test]
    fn needs_dart_js_detects_js_rules() {
        let js_source = r#"{"bookSourceUrl":"http://x.com","ruleSearch":{"bookList":"<js>1</js>"}}"#;
        let js = BookSource::from_json(js_source).unwrap();
        assert!(js.needs_dart_js());
        assert!(!fixture_source().needs_dart_js());
    }

    #[test]
    fn parse_url_config_replaces_page_placeholder() {
        let cfg = crate::http::client::parse_url_config_with_page(
            "/sort/1_{{page}}/",
            "",
            3,
        );
        assert_eq!(cfg.url, "/sort/1_3/");
    }
}
