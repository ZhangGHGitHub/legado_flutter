use crate::api::NoteDto;
use crate::db;
use serde_json::Value;

fn parse_note_json(raw: &str) -> Result<NoteDto, String> {
    let v: Value = serde_json::from_str(raw).map_err(|e| e.to_string())?;
    Ok(NoteDto {
        id: v
            .get("id")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_id: v
            .get("bookId")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        chapter_title: v
            .get("chapterTitle")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        selected_text: v
            .get("selectedText")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        note_content: v
            .get("noteContent")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        position: v.get("position").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        chapter_pos: v.get("chapterPos").and_then(|x| x.as_i64()).unwrap_or(-1) as i32,
        created_at: v
            .get("createdAt")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
    })
}

pub fn upsert_note(
    id: &str,
    book_id: &str,
    chapter_title: &str,
    selected_text: &str,
    note_content: &str,
    position: i32,
    chapter_pos: i32,
) -> Result<(), String> {
    db::db_upsert_note(
        id.to_string(),
        book_id.to_string(),
        chapter_title.to_string(),
        selected_text.to_string(),
        note_content.to_string(),
        position,
        chapter_pos,
    )
}

pub fn delete_note(id: &str) -> Result<(), String> {
    db::db_delete_note(id.to_string())
}

pub fn list_notes(book_id: String) -> Result<Vec<NoteDto>, String> {
    let filter = if book_id.is_empty() {
        None
    } else {
        Some(book_id)
    };
    let rows = db::db_list_notes(filter)?;
    rows.iter().map(|s| parse_note_json(s)).collect()
}

pub fn export_notes_markdown(book_id: String) -> Result<String, String> {
    let filter = if book_id.is_empty() {
        None
    } else {
        Some(book_id)
    };
    db::db_export_notes_markdown(filter)
}
