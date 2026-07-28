//! 可乐小说（kelexs）目录离线回归：chapterList JS + tocUrl JS + 上游错误页

use legado_engine::model::book_source::BookSource;
use legado_engine::rule::html_toc;
use legado_engine::rule::js_engine;

/// 与 tools/_source_https___www_rrssk_com_.json 对齐的精简书源
fn kele_source_json() -> String {
    r##"{
        "bookSourceName": "可乐小说",
        "bookSourceUrl": "https://www.rrssk.com/",
        "ruleBookInfo": {
            "tocUrl": "<js>var tocUrl=baseUrl.replace('/book/','/chapter/');try{var html=java.ajax(book.bookUrl);if(html){var jsMatch=html.match(/script type=\"text\\/javascript\" src=\"(\\/templates\\/js\\/[A-Za-z0-9]+\\.js)\"/)||html.match(/src=\"(\\/templates\\/js\\/[A-Za-z0-9]+\\.js)\"/);if(jsMatch){var jsUrl='https://www.kelexs.com'+jsMatch[1];var jsContent=java.ajax(jsUrl);if(jsContent){var keyMatch=jsContent.match(/new AESCrypt\\('([A-Za-z0-9]{32})'\\)/);var ivMatch=jsContent.match(/CryptoJS\\.enc\\.Utf8\\.parse\\('(\\d{16})'\\)/);if(keyMatch){cache.put('kelexs_key',keyMatch[1],86400);}if(ivMatch){cache.put('kelexs_iv',ivMatch[1],86400);}}}}}catch(e){}tocUrl</js>"
        },
        "ruleToc": {
            "chapterList": "<js>var resStr = result.toString().trim(); var elements = []; if (resStr.charAt(0) == '{' || resStr.charAt(0) == '[') { var parsed = false; try { var json = JSON.parse(resStr); if (json.code == 0 && json.data && json.data.length > 0) { for (var i = 0; i < json.data.length; i++) { var ch = json.data[i]; elements.push({ chaptername: ch.chaptername, chapterurl: 'https://www.kelexs.com' + ch.chapterurl }); } parsed = true; } } catch (e) {} if (!parsed || elements.length == 0) { var nameRegex = /\"chaptername\":\"([^\"]+)\"/g; var urlRegex = /\"chapterurl\":\"([^\"]+)\"/g; var names = []; var urls = []; var m; while ((m = nameRegex.exec(resStr)) !== null) { names.push(m[1]); } while ((m = urlRegex.exec(resStr)) !== null) { urls.push(m[1]); } for (var i = 0; i < names.length && i < urls.length; i++) { elements.push({ chaptername: names[i], chapterurl: 'https://www.kelexs.com' + urls[i] }); } } } else { var startIdx = resStr.indexOf('class=\"chapList chapListBody\"'); if (startIdx == -1) { startIdx = resStr.indexOf(\"class='chapList chapListBody'\"); } if (startIdx != -1) { var endIdx = resStr.indexOf('</ul>', startIdx); if (endIdx != -1) { var section = resStr.substring(startIdx, endIdx + 5); var liRegex = /<li[\\s\\S]*?<\\/li>/g; var m; while ((m = liRegex.exec(section)) !== null) { var aMatch = m[0].match(/<a\\s+[^>]*href=\"([^\"]+)\"[^>]*>([^<]+)<\\/a>/i); if (aMatch) { elements.push({ chaptername: aMatch[2], chapterurl: 'https://www.kelexs.com' + aMatch[1] }); } } } } } elements</js>",
            "chapterName": "chaptername",
            "chapterUrl": "chapterurl"
        }
    }"##
    .to_string()
}

const CHAP_LIST_HTML: &str = r#"<!DOCTYPE html><html><body>
<ul class="chapList chapListBody">
<li><a href="/read/a1.html">第一章 序章</a></li>
<li><a href="/read/a2.html">第二章 崛起</a></li>
<li><a href="/read/a3.html">第三章 风起</a></li>
</ul>
</body></html>"#;

#[test]
fn kele_chapter_list_js_fixture_yields_chapters() {
    let source = BookSource::from_json(&kele_source_json()).unwrap();
    let chapters = html_toc::parse_html_toc_at(
        CHAP_LIST_HTML,
        &source,
        "https://www.kelexs.com/chapter/ABC.html",
    )
    .unwrap();
    assert!(
        chapters.len() >= 3,
        "expected N>0 chapters from chapList fixture, got {}",
        chapters.len()
    );
    assert_eq!(chapters[0].title, "第一章 序章");
    assert_eq!(chapters[0].url, "https://www.kelexs.com/read/a1.html");
    assert_eq!(chapters[2].url, "https://www.kelexs.com/read/a3.html");
}

#[test]
fn kele_toc_json_page_fixture_yields_chapters() {
    let source = BookSource::from_json(&kele_source_json()).unwrap();
    let json = r#"{"code":0,"data":[
        {"chaptername":"第四百章","chapterurl":"/read/x.html"},
        {"chaptername":"第四百零一章","chapterurl":"/read/y.html"}
    ]}"#;
    let chapters =
        html_toc::parse_html_toc_at(json, &source, "https://www.kelexs.com/index.php?page=2")
            .unwrap();
    assert_eq!(chapters.len(), 2);
    assert_eq!(chapters[0].url, "https://www.kelexs.com/read/x.html");
}

#[test]
fn kele_toc_url_js_without_ajax_still_rewrites_path() {
    let _ = js_engine::reset_cache();
    let source = BookSource::from_json(&kele_source_json()).unwrap();
    let script = js_engine::extract_js_block(&source.rule_book_info_toc_url).unwrap();
    let out = js_engine::run_with_result_opts(
        &script,
        "",
        "",
        "https://www.kelexs.com/book/AIJGIFF.html",
        Some("https://www.kelexs.com/book/AIJGIFF.html"),
    )
    .unwrap();
    assert_eq!(out.trim(), "https://www.kelexs.com/chapter/AIJGIFF.html");
}

#[test]
fn kele_sql_error_body_yields_zero_chapters() {
    let source = BookSource::from_json(&kele_source_json()).unwrap();
    let err_body = "数据库连接失败:SQLSTATE[08004] [1040] Too many connections";
    let chapters =
        html_toc::parse_html_toc_at(err_body, &source, "https://www.kelexs.com/chapter/ABC.html")
            .unwrap();
    assert!(chapters.is_empty(), "SQL error page must not fake chapters");

    // 若站方恢复正常 HTML，离线 chapList fixture 仍保证管道 N>0
    let ok = html_toc::parse_html_toc_at(
        CHAP_LIST_HTML,
        &source,
        "https://www.kelexs.com/chapter/ABC.html",
    )
    .unwrap();
    assert!(!ok.is_empty());
}
