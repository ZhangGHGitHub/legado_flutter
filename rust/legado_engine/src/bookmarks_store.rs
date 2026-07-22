use crate::api::BookmarkDto;
use crate::db;
use serde_json::Value;

fn parse_bookmark_json(raw: &str) -> Result<BookmarkDto, String> {
    let v: Value = serde_json::from_str(raw).map_err(|e| e.to_string())?;
    Ok(BookmarkDto {
        time: v.get("time").and_then(|x| x.as_i64()).unwrap_or(0),
        book_id: v
            .get("bookId")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_name: v
            .get("bookName")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_author: v
            .get("bookAuthor")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        chapter_index: v.get("chapterIndex").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        chapter_pos: v.get("chapterPos").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        chapter_name: v
            .get("chapterName")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_text: v
            .get("bookText")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        content: v
            .get("content")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
    })
}

pub fn upsert_bookmark(
    time: i64,
    book_id: &str,
    book_name: &str,
    book_author: &str,
    chapter_index: i32,
    chapter_pos: i32,
    chapter_name: &str,
    book_text: &str,
    content: &str,
) -> Result<(), String> {
    db::db_upsert_bookmark(
        time,
        book_id.to_string(),
        book_name.to_string(),
        book_author.to_string(),
        chapter_index,
        chapter_pos,
        chapter_name.to_string(),
        book_text.to_string(),
        content.to_string(),
    )
}

pub fn delete_bookmark(time: i64) -> Result<(), String> {
    db::db_delete_bookmark(time)
}

pub fn list_bookmarks(book_id: String) -> Result<Vec<BookmarkDto>, String> {
    let filter = if book_id.is_empty() {
        None
    } else {
        Some(book_id)
    };
    db::db_list_bookmarks(filter)
        .and_then(|rows| rows.iter().map(|s| parse_bookmark_json(s)).collect())
}
