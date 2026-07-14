//! Rust 本地数据库 — 与 Flutter `legado.db` schema v7 对齐（Phase C）

use once_cell::sync::OnceCell;
use rusqlite::{params, Connection};
use serde_json::{json, Value};
use std::sync::Mutex;
use thiserror::Error;

const SCHEMA_VERSION: i32 = 9;

static DB: OnceCell<Mutex<EngineDb>> = OnceCell::new();

#[derive(Error, Debug)]
pub enum DbError {
    #[error("sqlite: {0}")]
    Sqlite(#[from] rusqlite::Error),
    #[error("{0}")]
    Message(String),
}

/// 引擎本地 SQLite
pub struct EngineDb {
    conn: Connection,
}

impl EngineDb {
    pub fn open(path: &str) -> Result<Self, DbError> {
        let conn = Connection::open(path)?;
        Self::init_schema(&conn)?;
        Ok(Self { conn })
    }

    pub fn open_in_memory() -> Result<Self, DbError> {
        Self::open(":memory:")
    }

    fn init_schema(conn: &Connection) -> Result<(), DbError> {
        conn.execute_batch(
            "PRAGMA foreign_keys = ON;
             CREATE TABLE IF NOT EXISTS books (
               id TEXT PRIMARY KEY,
               name TEXT NOT NULL,
               author TEXT DEFAULT '未知作者',
               coverUrl TEXT DEFAULT '',
               type TEXT DEFAULT 'online',
               progress REAL DEFAULT 0.0,
               currentChapter TEXT,
               lastChapter TEXT DEFAULT '',
               currentPageIndex INTEGER DEFAULT 0,
               isFavorite INTEGER DEFAULT 0,
               sourceUrl TEXT DEFAULT '',
               description TEXT DEFAULT '',
               bookSourceUrl TEXT DEFAULT '',
               bookGroup TEXT DEFAULT '',
               updatedAt TEXT DEFAULT (datetime('now'))
             );
             CREATE TABLE IF NOT EXISTS book_sources (
               bookSourceUrl TEXT PRIMARY KEY,
               bookSourceName TEXT NOT NULL,
               enabled INTEGER DEFAULT 1,
               bookSourceType TEXT DEFAULT '0',
               bookSourceGroup TEXT DEFAULT '',
               ruleSearchUrl TEXT DEFAULT '',
               ruleSearchList TEXT DEFAULT '',
               ruleSearchName TEXT DEFAULT '',
               ruleSearchAuthor TEXT DEFAULT '',
               ruleSearchCoverUrl TEXT DEFAULT '',
               ruleSearchKind TEXT DEFAULT '',
               ruleSearchNote TEXT DEFAULT '',
               ruleBookUrlPattern TEXT DEFAULT '',
               ruleBookName TEXT DEFAULT '',
               ruleBookAuthor TEXT DEFAULT '',
               ruleBookCoverUrl TEXT DEFAULT '',
               ruleBookKind TEXT DEFAULT '',
               ruleBookNote TEXT DEFAULT '',
               ruleBookLastChapter TEXT DEFAULT '',
               ruleChapterList TEXT DEFAULT '',
               ruleChapterName TEXT DEFAULT '',
               ruleChapterUrl TEXT DEFAULT '',
               ruleChapterUrlIsFull TEXT DEFAULT '',
               ruleContentUrl TEXT DEFAULT '',
               ruleContent TEXT DEFAULT '',
               ruleContentRemove TEXT DEFAULT '',
               rulePageUrl TEXT DEFAULT '',
               rulePageNext TEXT DEFAULT '',
               rawSourceJson TEXT DEFAULT '',
               createdAt TEXT DEFAULT (datetime('now'))
             );
             CREATE TABLE IF NOT EXISTS chapters (
               id TEXT PRIMARY KEY,
               bookId TEXT NOT NULL,
               title TEXT NOT NULL,
               idx INTEGER NOT NULL,
               url TEXT DEFAULT '',
               isDownloaded INTEGER DEFAULT 0,
               content TEXT,
               FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
             );
             CREATE TABLE IF NOT EXISTS replace_rules (
               id TEXT PRIMARY KEY,
               name TEXT DEFAULT '',
               pattern TEXT NOT NULL,
               replacement TEXT DEFAULT '',
               isEnabled INTEGER DEFAULT 1,
               isRegex INTEGER DEFAULT 1
             );",
        )?;
        let current: i32 = conn.query_row("PRAGMA user_version", [], |r| r.get(0))?;
        if current < 8 {
            conn.execute_batch(
                "CREATE TABLE IF NOT EXISTS reading_records (
                   id TEXT PRIMARY KEY,
                   book_id TEXT NOT NULL,
                   book_name TEXT DEFAULT '',
                   date TEXT NOT NULL,
                   duration_seconds INTEGER DEFAULT 0,
                   read_chars INTEGER DEFAULT 0,
                   UNIQUE(book_id, date)
                 );
                 CREATE INDEX IF NOT EXISTS idx_reading_records_date ON reading_records(date);",
            )?;
        }
        if current < 9 {
            conn.execute_batch(
                "CREATE TABLE IF NOT EXISTS notes (
                   id TEXT PRIMARY KEY,
                   book_id TEXT NOT NULL,
                   chapter_title TEXT DEFAULT '',
                   selected_text TEXT NOT NULL,
                   note_content TEXT DEFAULT '',
                   position INTEGER DEFAULT 0,
                   created_at TEXT DEFAULT (datetime('now')),
                   FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
                 );
                 CREATE INDEX IF NOT EXISTS idx_notes_book_id ON notes(book_id);",
            )?;
        }
        if current < SCHEMA_VERSION {
            conn.execute_batch(&format!("PRAGMA user_version = {SCHEMA_VERSION};"))?;
        }
        Ok(())
    }

    pub fn schema_version(&self) -> Result<i32, DbError> {
        Ok(self.conn.query_row("PRAGMA user_version", [], |r| r.get(0))?)
    }

    pub fn insert_book_json(&self, book_json: &str) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(book_json)
            .map_err(|e| DbError::Message(format!("book JSON 无效: {e}")))?;
        let id = str_field(&v, "id")?;
        self.conn.execute(
            "INSERT INTO books (id, name, author, coverUrl, type, progress, currentChapter,
              lastChapter, currentPageIndex, isFavorite, sourceUrl, description, bookSourceUrl, bookGroup)
             VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14)
             ON CONFLICT(id) DO UPDATE SET
               name=excluded.name, author=excluded.author, coverUrl=excluded.coverUrl,
               type=excluded.type, progress=excluded.progress, currentChapter=excluded.currentChapter,
               lastChapter=excluded.lastChapter, currentPageIndex=excluded.currentPageIndex,
               isFavorite=excluded.isFavorite, sourceUrl=excluded.sourceUrl,
               description=excluded.description, bookSourceUrl=excluded.bookSourceUrl,
               bookGroup=excluded.bookGroup, updatedAt=datetime('now')",
            params![
                id,
                str_field(&v, "name").unwrap_or_else(|_| "未知".into()),
                str_field(&v, "author").unwrap_or_default(),
                str_field(&v, "coverUrl").unwrap_or_default(),
                str_field(&v, "type").unwrap_or_else(|_| "online".into()),
                f64_field(&v, "progress"),
                opt_str_field(&v, "currentChapter"),
                str_field(&v, "lastChapter").unwrap_or_default(),
                i64_field(&v, "currentPageIndex"),
                bool_field(&v, "isFavorite") as i64,
                str_field(&v, "sourceUrl").unwrap_or_default(),
                str_field(&v, "description").unwrap_or_default(),
                str_field(&v, "bookSourceUrl").unwrap_or_default(),
                str_field(&v, "group").or_else(|_| str_field(&v, "bookGroup")).unwrap_or_default(),
            ],
        )?;
        Ok(())
    }

    pub fn get_books_json(&self) -> Result<Vec<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, author, coverUrl, type, progress, currentChapter, lastChapter,
                    currentPageIndex, isFavorite, sourceUrl, description, bookSourceUrl, bookGroup
             FROM books ORDER BY updatedAt DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "name": row.get::<_, String>(1)?,
                "author": row.get::<_, String>(2)?,
                "coverUrl": row.get::<_, String>(3)?,
                "type": row.get::<_, String>(4)?,
                "progress": row.get::<_, f64>(5)?,
                "currentChapter": row.get::<_, Option<String>>(6)?,
                "lastChapter": row.get::<_, String>(7)?,
                "currentPageIndex": row.get::<_, i64>(8)?,
                "isFavorite": row.get::<_, i64>(9)? == 1,
                "sourceUrl": row.get::<_, String>(10)?,
                "description": row.get::<_, String>(11)?,
                "bookSourceUrl": row.get::<_, String>(12)?,
                "group": row.get::<_, String>(13)?,
            }))
        })?;
        rows.map(|r| {
            r.map(|v| v.to_string())
                .map_err(|e| DbError::Message(e.to_string()))
        })
        .collect()
    }

    pub fn update_book_progress(
        &self,
        book_id: &str,
        progress: f64,
        chapter: Option<&str>,
        page_index: i64,
    ) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE books SET progress=?1, currentChapter=?2, currentPageIndex=?3,
             updatedAt=datetime('now') WHERE id=?4",
            params![progress, chapter, page_index, book_id],
        )?;
        Ok(())
    }

    pub fn update_book_cover(&self, book_id: &str, cover_url: &str) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE books SET coverUrl=?1 WHERE id=?2",
            params![cover_url, book_id],
        )?;
        Ok(())
    }

    pub fn update_book_group(&self, book_id: &str, group: &str) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE books SET bookGroup=?1 WHERE id=?2",
            params![group, book_id],
        )?;
        Ok(())
    }

    pub fn delete_book(&self, book_id: &str) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM chapters WHERE bookId=?1", params![book_id])?;
        self.conn
            .execute("DELETE FROM books WHERE id=?1", params![book_id])?;
        Ok(())
    }

    pub fn upsert_source_json(&self, source_json: &str) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(source_json)
            .map_err(|e| DbError::Message(format!("书源 JSON 无效: {e}")))?;
        let url = str_field(&v, "bookSourceUrl")?;
        self.conn.execute(
            "INSERT INTO book_sources (
               bookSourceUrl, bookSourceName, enabled, bookSourceType, bookSourceGroup,
               ruleSearchUrl, ruleSearchList, ruleSearchName, ruleSearchAuthor,
               ruleSearchCoverUrl, ruleSearchKind, ruleSearchNote, ruleBookUrlPattern,
               ruleBookName, ruleBookAuthor, ruleBookCoverUrl, ruleBookKind, ruleBookNote,
               ruleBookLastChapter, ruleChapterList, ruleChapterName, ruleChapterUrl,
               ruleChapterUrlIsFull, ruleContentUrl, ruleContent, ruleContentRemove,
               rulePageUrl, rulePageNext, rawSourceJson)
             VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?23,?24,?25,?26,?27,?28,?29)
             ON CONFLICT(bookSourceUrl) DO UPDATE SET
               bookSourceName=excluded.bookSourceName,
               enabled=book_sources.enabled,
               bookSourceType=excluded.bookSourceType, bookSourceGroup=excluded.bookSourceGroup,
               ruleSearchUrl=excluded.ruleSearchUrl, rawSourceJson=excluded.rawSourceJson",
            params![
                url,
                str_field(&v, "bookSourceName").unwrap_or_else(|_| "未命名书源".into()),
                bool_field(&v, "enabled") as i64,
                str_field(&v, "bookSourceType").unwrap_or_else(|_| "0".into()),
                str_field(&v, "bookSourceGroup").unwrap_or_default(),
                str_field(&v, "ruleSearchUrl").unwrap_or_default(),
                str_field(&v, "ruleSearchList").unwrap_or_default(),
                str_field(&v, "ruleSearchName").unwrap_or_default(),
                str_field(&v, "ruleSearchAuthor").unwrap_or_default(),
                str_field(&v, "ruleSearchCoverUrl").unwrap_or_default(),
                str_field(&v, "ruleSearchKind").unwrap_or_default(),
                str_field(&v, "ruleSearchNote").unwrap_or_default(),
                str_field(&v, "ruleBookUrlPattern").unwrap_or_default(),
                str_field(&v, "ruleBookName").unwrap_or_default(),
                str_field(&v, "ruleBookAuthor").unwrap_or_default(),
                str_field(&v, "ruleBookCoverUrl").unwrap_or_default(),
                str_field(&v, "ruleBookKind").unwrap_or_default(),
                str_field(&v, "ruleBookNote").unwrap_or_default(),
                str_field(&v, "ruleBookLastChapter").unwrap_or_default(),
                str_field(&v, "ruleChapterList").unwrap_or_default(),
                str_field(&v, "ruleChapterName").unwrap_or_default(),
                str_field(&v, "ruleChapterUrl").unwrap_or_default(),
                str_field(&v, "ruleChapterUrlIsFull").unwrap_or_default(),
                str_field(&v, "ruleContentUrl").unwrap_or_default(),
                str_field(&v, "ruleContent").unwrap_or_default(),
                str_field(&v, "ruleContentRemove").unwrap_or_default(),
                str_field(&v, "rulePageUrl").unwrap_or_default(),
                str_field(&v, "rulePageNext").unwrap_or_default(),
                str_field(&v, "rawSourceJson").unwrap_or(source_json.to_string()),
            ],
        )?;
        Ok(())
    }

    pub fn get_sources_json(&self, enabled_only: bool) -> Result<Vec<String>, DbError> {
        let sql = if enabled_only {
            "SELECT rawSourceJson, bookSourceUrl, bookSourceName, enabled, bookSourceGroup,
                    ruleSearchUrl FROM book_sources WHERE enabled=1 ORDER BY createdAt DESC"
        } else {
            "SELECT rawSourceJson, bookSourceUrl, bookSourceName, enabled, bookSourceGroup,
                    ruleSearchUrl FROM book_sources ORDER BY createdAt DESC"
        };
        let mut stmt = self.conn.prepare(sql)?;
        let rows = stmt.query_map([], |row| {
            Ok(source_row_to_json(row)?)
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    pub fn toggle_source(&self, url: &str, enabled: bool) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE book_sources SET enabled=?1 WHERE bookSourceUrl=?2",
            params![enabled as i64, url],
        )?;
        Ok(())
    }

    pub fn delete_source(&self, url: &str) -> Result<(), DbError> {
        self.conn.execute(
            "DELETE FROM book_sources WHERE bookSourceUrl=?1",
            params![url],
        )?;
        Ok(())
    }

    pub fn insert_chapters_json(&self, chapters_json: &str) -> Result<(), DbError> {
        let arr: Vec<Value> = serde_json::from_str(chapters_json)
            .map_err(|e| DbError::Message(format!("chapters JSON 无效: {e}")))?;
        for ch in arr {
            let id = str_field(&ch, "id")?;
            // TOC 刷新时常见 content=null / isDownloaded=0；勿覆盖已缓存正文
            self.conn.execute(
                "INSERT INTO chapters (id, bookId, title, idx, url, isDownloaded, content)
                 VALUES (?1,?2,?3,?4,?5,?6,?7)
                 ON CONFLICT(id) DO UPDATE SET
                   title=excluded.title,
                   idx=excluded.idx,
                   url=excluded.url,
                   isDownloaded=CASE
                     WHEN excluded.isDownloaded != 0 THEN 1
                     ELSE chapters.isDownloaded
                   END,
                   content=CASE
                     WHEN excluded.content IS NOT NULL AND excluded.content != ''
                       THEN excluded.content
                     ELSE chapters.content
                   END",
                params![
                    id,
                    str_field(&ch, "bookId")?,
                    str_field(&ch, "title").unwrap_or_default(),
                    i64_field_idx(&ch, "index"),
                    str_field(&ch, "url").unwrap_or_default(),
                    bool_field(&ch, "isDownloaded") as i64,
                    opt_str_field(&ch, "content"),
                ],
            )?;
        }
        Ok(())
    }

    pub fn get_chapters_json(&self, book_id: &str) -> Result<Vec<String>, DbError> {
        // 目录展示不带 content：对齐 Legado ChapterList 只查元数据，避免千章×正文撑爆/拖慢
        let mut stmt = self.conn.prepare(
            "SELECT id, bookId, title, idx, url, isDownloaded
             FROM chapters WHERE bookId=?1 ORDER BY idx ASC",
        )?;
        let rows = stmt.query_map(params![book_id], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "bookId": row.get::<_, String>(1)?,
                "title": row.get::<_, String>(2)?,
                "index": row.get::<_, i64>(3)?,
                "url": row.get::<_, String>(4)?,
                "isDownloaded": row.get::<_, i64>(5)? == 1,
                "content": null,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    /// 单章正文（文件缓存未命中时的 DB 回落）
    pub fn get_chapter_content(&self, chapter_id: &str) -> Result<Option<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT content FROM chapters WHERE id=?1 AND isDownloaded=1",
        )?;
        let mut rows = stmt.query(params![chapter_id])?;
        if let Some(row) = rows.next()? {
            Ok(row.get::<_, Option<String>>(0)?)
        } else {
            Ok(None)
        }
    }

    pub fn save_chapter_content(&self, chapter_id: &str, content: &str) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE chapters SET content=?1, isDownloaded=1 WHERE id=?2",
            params![content, chapter_id],
        )?;
        Ok(())
    }

    pub fn book_count(&self) -> Result<i64, DbError> {
        Ok(self
            .conn
            .query_row("SELECT COUNT(*) FROM books", [], |r| r.get(0))?)
    }

    pub fn upsert_replace_rule_json(&self, rule_json: &str) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(rule_json)
            .map_err(|e| DbError::Message(format!("replace rule JSON 无效: {e}")))?;
        self.conn.execute(
            "INSERT INTO replace_rules (id, name, pattern, replacement, isEnabled, isRegex)
             VALUES (?1,?2,?3,?4,?5,?6)
             ON CONFLICT(id) DO UPDATE SET
               name=excluded.name, pattern=excluded.pattern,
               replacement=excluded.replacement, isEnabled=excluded.isEnabled,
               isRegex=excluded.isRegex",
            params![
                str_field(&v, "id")?,
                str_field(&v, "name").unwrap_or_default(),
                str_field(&v, "pattern")?,
                str_field(&v, "replacement").unwrap_or_default(),
                bool_field(&v, "isEnabled") as i64,
                bool_field(&v, "isRegex") as i64,
            ],
        )?;
        Ok(())
    }

    pub fn get_replace_rules_json(&self) -> Result<Vec<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, pattern, replacement, isEnabled, isRegex
             FROM replace_rules ORDER BY name ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "name": row.get::<_, String>(1)?,
                "pattern": row.get::<_, String>(2)?,
                "replacement": row.get::<_, String>(3)?,
                "isEnabled": row.get::<_, i64>(4)? == 1,
                "isRegex": row.get::<_, i64>(5)? == 1,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    pub fn toggle_replace_rule(&self, id: &str, enabled: bool) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE replace_rules SET isEnabled=?1 WHERE id=?2",
            params![enabled as i64, id],
        )?;
        Ok(())
    }

    pub fn delete_replace_rule(&self, id: &str) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM replace_rules WHERE id=?1", params![id])?;
        Ok(())
    }

    pub fn clear_replace_rules(&self) -> Result<(), DbError> {
        self.conn.execute("DELETE FROM replace_rules", [])?;
        Ok(())
    }

    pub fn record_reading(
        &self,
        book_id: &str,
        book_name: &str,
        chars: i64,
        duration_seconds: i64,
    ) -> Result<(), DbError> {
        let date: String = self
            .conn
            .query_row("SELECT date('now', 'localtime')", [], |r| r.get(0))?;
        let id = format!("{book_id}_{date}");
        self.conn.execute(
            "INSERT INTO reading_records (id, book_id, book_name, date, duration_seconds, read_chars)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(book_id, date) DO UPDATE SET
               read_chars = read_chars + excluded.read_chars,
               duration_seconds = duration_seconds + excluded.duration_seconds,
               book_name = excluded.book_name",
            params![id, book_id, book_name, date, duration_seconds, chars],
        )?;
        Ok(())
    }

    fn reading_days_filter(&self, range: &str) -> &'static str {
        match range {
            "week" => "-7 days",
            "month" => "-30 days",
            "year" => "-365 days",
            _ => "-30 days",
        }
    }

    pub fn get_reading_stats_json(&self, range: &str) -> Result<String, DbError> {
        let (total_chars, total_duration): (i64, i64) = self.conn.query_row(
            "SELECT COALESCE(SUM(read_chars),0), COALESCE(SUM(duration_seconds),0) FROM reading_records",
            [],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )?;

        let (today_chars, today_duration): (i64, i64) = self.conn.query_row(
            "SELECT COALESCE(SUM(read_chars),0), COALESCE(SUM(duration_seconds),0)
             FROM reading_records WHERE date = date('now', 'localtime')",
            [],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )?;

        let week_chars: i64 = self.conn.query_row(
            "SELECT COALESCE(SUM(read_chars),0) FROM reading_records
             WHERE date >= date('now', 'localtime', '-7 days')",
            [],
            |r| r.get(0),
        )?;

        let days = self.reading_days_filter(range);
        let sql = format!(
            "SELECT date, COALESCE(SUM(read_chars),0), COALESCE(SUM(duration_seconds),0)
             FROM reading_records
             WHERE date >= date('now', 'localtime', '{days}')
             GROUP BY date ORDER BY date ASC"
        );

        let mut stmt = self.conn.prepare(&sql)?;
        let daily = stmt
            .query_map([], |row| {
                Ok(json!({
                    "date": row.get::<_, String>(0)?,
                    "chars": row.get::<_, i64>(1)?,
                    "durationSeconds": row.get::<_, i64>(2)?,
                }))
            })?
            .map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect::<Result<Vec<_>, _>>()?;

        Ok(json!({
            "totalChars": total_chars,
            "totalDurationSeconds": total_duration,
            "todayChars": today_chars,
            "todayDurationSeconds": today_duration,
            "weekChars": week_chars,
            "daily": daily,
        })
        .to_string())
    }

    pub fn get_book_reading_stats_json(&self, book_id: &str) -> Result<String, DbError> {
        let (duration, chars, start_date, last_date, days): (i64, i64, Option<String>, Option<String>, i64) =
            self.conn.query_row(
                "SELECT COALESCE(SUM(duration_seconds),0), COALESCE(SUM(read_chars),0),
                        MIN(date), MAX(date), COUNT(DISTINCT date)
                 FROM reading_records WHERE book_id = ?1",
                params![book_id],
                |r| {
                    Ok((
                        r.get(0)?,
                        r.get(1)?,
                        r.get(2)?,
                        r.get(3)?,
                        r.get(4)?,
                    ))
                },
            )?;

        Ok(json!({
            "durationSeconds": duration,
            "readChars": chars,
            "startDate": start_date,
            "lastDate": last_date,
            "readingDays": days,
        })
        .to_string())
    }

    pub fn upsert_note(
        &self,
        id: &str,
        book_id: &str,
        chapter_title: &str,
        selected_text: &str,
        note_content: &str,
        position: i64,
    ) -> Result<(), DbError> {
        self.conn.execute(
            "INSERT INTO notes (id, book_id, chapter_title, selected_text, note_content, position)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(id) DO UPDATE SET
               chapter_title = excluded.chapter_title,
               selected_text = excluded.selected_text,
               note_content = excluded.note_content,
               position = excluded.position",
            params![
                id,
                book_id,
                chapter_title,
                selected_text,
                note_content,
                position
            ],
        )?;
        Ok(())
    }

    pub fn delete_note(&self, id: &str) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM notes WHERE id = ?1", params![id])?;
        Ok(())
    }

    pub fn list_notes_json(&self, book_id: Option<&str>) -> Result<Vec<String>, DbError> {
        let mut out = Vec::new();
        if let Some(bid) = book_id.filter(|s| !s.is_empty()) {
            let mut stmt = self.conn.prepare(
                "SELECT id, book_id, chapter_title, selected_text, note_content, position, created_at
                 FROM notes WHERE book_id = ?1 ORDER BY created_at DESC",
            )?;
            let rows = stmt.query_map(params![bid], |row| Self::map_note_row(row))?;
            for row in rows {
                out.push(row.map_err(|e| DbError::Message(e.to_string()))?);
            }
        } else {
            let mut stmt = self.conn.prepare(
                "SELECT id, book_id, chapter_title, selected_text, note_content, position, created_at
                 FROM notes ORDER BY created_at DESC",
            )?;
            let rows = stmt.query_map([], |row| Self::map_note_row(row))?;
            for row in rows {
                out.push(row.map_err(|e| DbError::Message(e.to_string()))?);
            }
        }
        Ok(out)
    }

    fn map_note_row(row: &rusqlite::Row<'_>) -> Result<String, rusqlite::Error> {
        Ok(json!({
            "id": row.get::<_, String>(0)?,
            "bookId": row.get::<_, String>(1)?,
            "chapterTitle": row.get::<_, String>(2)?,
            "selectedText": row.get::<_, String>(3)?,
            "noteContent": row.get::<_, String>(4)?,
            "position": row.get::<_, i64>(5)?,
            "createdAt": row.get::<_, String>(6)?,
        })
        .to_string())
    }

    pub fn export_notes_markdown(&self, book_id: Option<&str>) -> Result<String, DbError> {
        let notes = self.list_notes_json(book_id)?;
        let mut out = String::new();
        for raw in notes {
            let v: Value = serde_json::from_str(&raw)
                .map_err(|e| DbError::Message(format!("笔记 JSON 无效: {e}")))?;
            let chapter = str_field(&v, "chapterTitle").unwrap_or_default();
            let selected = str_field(&v, "selectedText")?;
            let content = str_field(&v, "noteContent").unwrap_or_default();
            let created = str_field(&v, "createdAt").unwrap_or_default();
            out.push_str(&format!("## {chapter}\n\n"));
            if !selected.is_empty() {
                out.push_str("> ");
                out.push_str(&selected.replace('\n', "\n> "));
                out.push_str("\n\n");
            }
            if !content.is_empty() {
                out.push_str(&content);
                out.push('\n');
            }
            out.push_str(&format!("\n---\ncreated: {created}\n\n"));
        }
        Ok(out)
    }

    pub fn export_reading_records(&self, format: &str) -> Result<String, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT date, book_id, book_name, read_chars, duration_seconds
             FROM reading_records ORDER BY date DESC, book_name ASC",
        )?;
        let rows = stmt
            .query_map([], |row| {
                Ok((
                    row.get::<_, String>(0)?,
                    row.get::<_, String>(1)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, i64>(3)?,
                    row.get::<_, i64>(4)?,
                ))
            })?
            .map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect::<Result<Vec<_>, _>>()?;

        if format.eq_ignore_ascii_case("csv") {
            let mut out = String::from("date,book_id,book_name,read_chars,duration_seconds\n");
            for (date, book_id, book_name, chars, duration) in rows {
                let name = book_name.replace('"', "\"\"");
                out.push_str(&format!(
                    "{date},\"{book_id}\",\"{name}\",{chars},{duration}\n"
                ));
            }
            return Ok(out);
        }

        let list: Vec<Value> = rows
            .into_iter()
            .map(|(date, book_id, book_name, chars, duration)| {
                json!({
                    "date": date,
                    "bookId": book_id,
                    "bookName": book_name,
                    "readChars": chars,
                    "durationSeconds": duration,
                })
            })
            .collect();
        Ok(serde_json::to_string_pretty(&list)
            .map_err(|e| DbError::Message(e.to_string()))?)
    }

    pub fn get_all_chapters_json(&self) -> Result<Vec<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, bookId, title, idx, url, isDownloaded, content
             FROM chapters ORDER BY bookId ASC, idx ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "bookId": row.get::<_, String>(1)?,
                "title": row.get::<_, String>(2)?,
                "index": row.get::<_, i64>(3)?,
                "url": row.get::<_, String>(4)?,
                "isDownloaded": row.get::<_, i64>(5)? == 1,
                "content": row.get::<_, Option<String>>(6)?,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    pub fn export_backup_json(&self) -> Result<String, DbError> {
        let books: Vec<Value> = self
            .get_books_json()?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let sources: Vec<Value> = self
            .get_sources_json(false)?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let chapters: Vec<Value> = self
            .get_all_chapters_json()?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let replace_rules: Vec<Value> = self
            .get_replace_rules_json()?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let reading_records: Vec<Value> =
            serde_json::from_str(&self.export_reading_records("json")?).unwrap_or_default();
        let notes: Vec<Value> = self
            .list_notes_json(None)?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();

        Ok(json!({
            "version": 1,
            "schemaVersion": SCHEMA_VERSION,
            "books": books,
            "sources": sources,
            "chapters": chapters,
            "replaceRules": replace_rules,
            "readingRecords": reading_records,
            "notes": notes,
        })
        .to_string())
    }

    fn clear_all_for_restore(&self) -> Result<(), DbError> {
        self.conn.execute_batch(
            "DELETE FROM chapters;
             DELETE FROM books;
             DELETE FROM book_sources;
             DELETE FROM replace_rules;
             DELETE FROM reading_records;
             DELETE FROM notes;",
        )?;
        Ok(())
    }

    fn restore_reading_record(&self, entry: &Value) -> Result<(), DbError> {
        let book_id = str_field(entry, "bookId")?;
        let book_name = str_field(entry, "bookName").unwrap_or_default();
        let date = str_field(entry, "date")?;
        let chars = entry
            .get("readChars")
            .and_then(|v| v.as_i64())
            .unwrap_or(0);
        let duration = entry
            .get("durationSeconds")
            .and_then(|v| v.as_i64())
            .unwrap_or(0);
        let id = format!("{book_id}_{date}");
        self.conn.execute(
            "INSERT INTO reading_records (id, book_id, book_name, date, duration_seconds, read_chars)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(book_id, date) DO UPDATE SET
               read_chars = excluded.read_chars,
               duration_seconds = excluded.duration_seconds,
               book_name = excluded.book_name",
            params![id, book_id, book_name, date, duration, chars],
        )?;
        Ok(())
    }

    fn restore_note(&self, entry: &Value) -> Result<(), DbError> {
        let id = str_field(entry, "id")?;
        let book_id = str_field(entry, "bookId")?;
        let chapter_title = str_field(entry, "chapterTitle").unwrap_or_default();
        let selected_text = str_field(entry, "selectedText")?;
        let note_content = str_field(entry, "noteContent").unwrap_or_default();
        let position = entry
            .get("position")
            .and_then(|v| v.as_i64())
            .unwrap_or(0);
        let created_at = str_field(entry, "createdAt").unwrap_or_default();
        self.conn.execute(
            "INSERT INTO notes (id, book_id, chapter_title, selected_text, note_content, position, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(id) DO UPDATE SET
               chapter_title = excluded.chapter_title,
               selected_text = excluded.selected_text,
               note_content = excluded.note_content,
               position = excluded.position,
               created_at = excluded.created_at",
            params![
                id,
                book_id,
                chapter_title,
                selected_text,
                note_content,
                position,
                created_at
            ],
        )?;
        Ok(())
    }

    pub fn restore_backup_json(&self, raw: &str, replace: bool) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(raw)
            .map_err(|e| DbError::Message(format!("备份 JSON 无效: {e}")))?;
        if replace {
            self.clear_all_for_restore()?;
        }

        if let Some(arr) = v.get("sources").and_then(|x| x.as_array()) {
            for item in arr {
                self.upsert_source_json(&item.to_string())?;
            }
        }
        if let Some(arr) = v.get("books").and_then(|x| x.as_array()) {
            for item in arr {
                self.insert_book_json(&item.to_string())?;
            }
        }
        if let Some(arr) = v.get("chapters").and_then(|x| x.as_array()) {
            if !arr.is_empty() {
                self.insert_chapters_json(&serde_json::to_string(arr).unwrap())?;
            }
        }
        if let Some(arr) = v.get("replaceRules").and_then(|x| x.as_array()) {
            for item in arr {
                self.upsert_replace_rule_json(&item.to_string())?;
            }
        }
        if let Some(arr) = v.get("readingRecords").and_then(|x| x.as_array()) {
            for item in arr {
                self.restore_reading_record(item)?;
            }
        }
        if let Some(arr) = v.get("notes").and_then(|x| x.as_array()) {
            for item in arr {
                self.restore_note(item)?;
            }
        }
        Ok(())
    }
}

pub fn init_global(path: &str) -> Result<(), DbError> {
    let db = EngineDb::open(path)?;
    DB.set(Mutex::new(db))
        .map_err(|_| DbError::Message("数据库已初始化".into()))?;
    Ok(())
}

pub fn is_initialized() -> bool {
    DB.get().is_some()
}

fn with_db<F, T>(f: F) -> Result<T, String>
where
    F: FnOnce(&EngineDb) -> Result<T, DbError>,
{
    let cell = DB
        .get()
        .ok_or_else(|| "数据库未初始化".to_string())?;
    let guard = cell
        .lock()
        .map_err(|_| "数据库锁失败".to_string())?;
    f(&guard).map_err(|e| e.to_string())
}

pub fn db_init(path: String) -> Result<(), String> {
    init_global(&path).map_err(|e| e.to_string())
}

pub fn db_schema_version() -> Result<i32, String> {
    with_db(|db| db.schema_version())
}

pub fn db_insert_book(book_json: String) -> Result<(), String> {
    with_db(|db| db.insert_book_json(&book_json))
}

pub fn db_get_books() -> Result<Vec<String>, String> {
    with_db(|db| db.get_books_json())
}

pub fn db_delete_book(book_id: String) -> Result<(), String> {
    with_db(|db| db.delete_book(&book_id))
}

pub fn db_upsert_source(source_json: String) -> Result<(), String> {
    with_db(|db| db.upsert_source_json(&source_json))
}

pub fn db_get_sources(enabled_only: bool) -> Result<Vec<String>, String> {
    with_db(|db| db.get_sources_json(enabled_only))
}

pub fn db_insert_chapters(chapters_json: String) -> Result<(), String> {
    with_db(|db| db.insert_chapters_json(&chapters_json))
}

pub fn db_get_chapters(book_id: String) -> Result<Vec<String>, String> {
    with_db(|db| db.get_chapters_json(&book_id))
}

pub fn db_update_book_progress(
    book_id: String,
    progress: f64,
    chapter: Option<String>,
    page_index: i32,
) -> Result<(), String> {
    with_db(|db| {
        db.update_book_progress(&book_id, progress, chapter.as_deref(), page_index as i64)
    })
}

pub fn db_update_book_cover(book_id: String, cover_url: String) -> Result<(), String> {
    with_db(|db| db.update_book_cover(&book_id, &cover_url))
}

pub fn db_update_book_group(book_id: String, group: String) -> Result<(), String> {
    with_db(|db| db.update_book_group(&book_id, &group))
}

pub fn db_save_chapter_content(chapter_id: String, content: String) -> Result<(), String> {
    with_db(|db| db.save_chapter_content(&chapter_id, &content))
}

pub fn db_toggle_source(url: String, enabled: bool) -> Result<(), String> {
    with_db(|db| db.toggle_source(&url, enabled))
}

pub fn db_delete_source(url: String) -> Result<(), String> {
    with_db(|db| db.delete_source(&url))
}

pub fn db_upsert_replace_rule(rule_json: String) -> Result<(), String> {
    with_db(|db| db.upsert_replace_rule_json(&rule_json))
}

pub fn db_get_replace_rules() -> Result<Vec<String>, String> {
    with_db(|db| db.get_replace_rules_json())
}

pub fn db_toggle_replace_rule(id: String, enabled: bool) -> Result<(), String> {
    with_db(|db| db.toggle_replace_rule(&id, enabled))
}

pub fn db_delete_replace_rule(id: String) -> Result<(), String> {
    with_db(|db| db.delete_replace_rule(&id))
}

pub fn db_clear_replace_rules() -> Result<(), String> {
    with_db(|db| db.clear_replace_rules())
}

pub fn db_record_reading(
    book_id: String,
    book_name: String,
    chars: i32,
    duration_seconds: i32,
) -> Result<(), String> {
    with_db(|db| {
        db.record_reading(
            &book_id,
            &book_name,
            chars as i64,
            duration_seconds as i64,
        )
    })
}

pub fn db_get_reading_stats(range: String) -> Result<String, String> {
    with_db(|db| db.get_reading_stats_json(&range))
}

pub fn db_get_book_reading_stats(book_id: String) -> Result<String, String> {
    with_db(|db| db.get_book_reading_stats_json(&book_id))
}

pub fn db_upsert_note(
    id: String,
    book_id: String,
    chapter_title: String,
    selected_text: String,
    note_content: String,
    position: i32,
) -> Result<(), String> {
    with_db(|db| {
        db.upsert_note(
            &id,
            &book_id,
            &chapter_title,
            &selected_text,
            &note_content,
            position as i64,
        )
    })
}

pub fn db_delete_note(id: String) -> Result<(), String> {
    with_db(|db| db.delete_note(&id))
}

pub fn db_list_notes(book_id: Option<String>) -> Result<Vec<String>, String> {
    with_db(|db| {
        db.list_notes_json(book_id.as_deref().filter(|s| !s.is_empty()))
    })
}

pub fn db_export_notes_markdown(book_id: Option<String>) -> Result<String, String> {
    with_db(|db| {
        db.export_notes_markdown(book_id.as_deref().filter(|s| !s.is_empty()))
    })
}

pub fn db_export_reading_records(format: String) -> Result<String, String> {
    with_db(|db| db.export_reading_records(&format))
}

pub fn db_export_backup() -> Result<String, String> {
    with_db(|db| db.export_backup_json())
}

pub fn db_restore_backup(json: String, replace: bool) -> Result<(), String> {
    with_db(|db| db.restore_backup_json(&json, replace))
}

fn str_field(v: &Value, key: &str) -> Result<String, DbError> {
    v.get(key)
        .and_then(|x| {
            if x.is_null() {
                None
            } else {
                Some(x.as_str().unwrap_or(&x.to_string()).to_string())
            }
        })
        .ok_or_else(|| DbError::Message(format!("缺少字段 {key}")))
}

fn opt_str_field(v: &Value, key: &str) -> Option<String> {
    v.get(key).and_then(|x| {
        if x.is_null() {
            None
        } else {
            Some(x.as_str().unwrap_or(&x.to_string()).to_string())
        }
    })
}

fn bool_field(v: &Value, key: &str) -> bool {
    v.get(key)
        .and_then(|x| x.as_bool())
        .unwrap_or_else(|| v.get(key).and_then(|x| x.as_i64()).unwrap_or(1) == 1)
}

/// 将 DB 行合并为书源 JSON：`rawSourceJson` 保留规则，但 `enabled` 等以列为准。
fn source_row_to_json(row: &rusqlite::Row<'_>) -> Result<String, rusqlite::Error> {
    let raw: String = row.get(0)?;
    let url: String = row.get(1)?;
    let name: String = row.get(2)?;
    let enabled: i64 = row.get(3)?;
    let group: String = row.get(4)?;
    let search_url: String = row.get(5)?;

    if !raw.is_empty() {
        if let Ok(mut v) = serde_json::from_str::<Value>(&raw) {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("enabled".to_string(), json!(enabled == 1));
                if !group.is_empty() {
                    obj.insert("bookSourceGroup".to_string(), json!(group));
                }
            }
            return Ok(v.to_string());
        }
    }

    Ok(json!({
        "bookSourceUrl": url,
        "bookSourceName": name,
        "enabled": enabled == 1,
        "bookSourceGroup": group,
        "ruleSearchUrl": search_url,
    })
    .to_string())
}

fn f64_field(v: &Value, key: &str) -> f64 {
    v.get(key).and_then(|x| x.as_f64()).unwrap_or(0.0)
}

fn i64_field(v: &Value, key: &str) -> i64 {
    v.get(key)
        .and_then(|x| x.as_i64())
        .unwrap_or_else(|| v.get(key).and_then(|x| x.as_f64()).unwrap_or(0.0) as i64)
}

fn i64_field_idx(v: &Value, key: &str) -> i64 {
    v.get(key)
        .or_else(|| v.get("idx"))
        .and_then(|x| x.as_i64())
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn in_memory_db_schema_and_book_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        assert_eq!(db.schema_version().unwrap(), SCHEMA_VERSION);
        db.insert_book_json(
            r#"{"id":"b1","name":"斗破","author":"土豆","sourceUrl":"http://x/1"}"#,
        )
        .unwrap();
        assert_eq!(db.book_count().unwrap(), 1);
        let books = db.get_books_json().unwrap();
        assert_eq!(books.len(), 1);
        assert!(books[0].contains("斗破"));
    }

    #[test]
    fn source_toggle_persists_over_raw_json() {
        let db = EngineDb::open_in_memory().unwrap();
        db.upsert_source_json(
            r#"{"bookSourceUrl":"https://a.test","bookSourceName":"A","enabled":true,"rawSourceJson":"{\"bookSourceUrl\":\"https://a.test\",\"enabled\":true}"}"#,
        )
        .unwrap();
        db.toggle_source("https://a.test", false).unwrap();

        let all = db.get_sources_json(false).unwrap();
        assert_eq!(all.len(), 1);
        let v: Value = serde_json::from_str(&all[0]).unwrap();
        assert_eq!(v.get("enabled").and_then(|x| x.as_bool()), Some(false));

        let enabled_only = db.get_sources_json(true).unwrap();
        assert!(enabled_only.is_empty());
    }

    #[test]
    fn backup_export_restore_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"b1","name":"测试书","author":"作者","bookSourceUrl":"https://x.com"}"#,
        )
        .unwrap();
        db.upsert_source_json(
            r#"{"bookSourceUrl":"https://x.com","bookSourceName":"测试源","enabled":true}"#,
        )
        .unwrap();
        db.insert_chapters_json(
            r#"[{"id":"c1","bookId":"b1","title":"第一章","index":0,"url":"/1"}]"#,
        )
        .unwrap();

        let backup = db.export_backup_json().unwrap();
        assert!(backup.contains("测试书"));
        assert!(backup.contains("测试源"));

        let db2 = EngineDb::open_in_memory().unwrap();
        db2.restore_backup_json(&backup, true).unwrap();
        assert_eq!(db2.get_books_json().unwrap().len(), 1);
        assert_eq!(db2.get_sources_json(false).unwrap().len(), 1);
        assert_eq!(db2.get_chapters_json("b1").unwrap().len(), 1);
    }

    #[test]
    fn reading_records_accumulate_and_export() {
        let db = EngineDb::open_in_memory().unwrap();
        db.record_reading("b1", "斗破", 1000, 300).unwrap();
        db.record_reading("b1", "斗破", 500, 120).unwrap();
        db.record_reading("b2", "遮天", 800, 200).unwrap();

        let stats_json = db.get_reading_stats_json("month").unwrap();
        let stats: Value = serde_json::from_str(&stats_json).unwrap();
        assert_eq!(stats.get("totalChars").and_then(|x| x.as_i64()), Some(2300));
        assert_eq!(
            stats.get("todayChars").and_then(|x| x.as_i64()),
            Some(2300)
        );

        let csv = db.export_reading_records("csv").unwrap();
        assert!(csv.starts_with("date,book_id,book_name,read_chars,duration_seconds"));
        assert!(csv.contains("斗破"));
        assert!(csv.contains("1500"));

        let json = db.export_reading_records("json").unwrap();
        let rows: Vec<Value> = serde_json::from_str(&json).unwrap();
        assert_eq!(rows.len(), 2);

        let book_stats_json = db.get_book_reading_stats_json("b1").unwrap();
        let book_stats: Value = serde_json::from_str(&book_stats_json).unwrap();
        assert_eq!(
            book_stats.get("readChars").and_then(|x| x.as_i64()),
            Some(1500)
        );
        assert_eq!(
            book_stats.get("durationSeconds").and_then(|x| x.as_i64()),
            Some(420)
        );
        assert_eq!(
            book_stats.get("readingDays").and_then(|x| x.as_i64()),
            Some(1)
        );
    }

    #[test]
    fn notes_crud_and_markdown_export() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"b1","name":"测试书","author":"作者","bookSourceUrl":"https://x.com"}"#,
        )
        .unwrap();

        db.upsert_note(
            "n1",
            "b1",
            "第一章",
            "选中片段",
            "我的想法",
            120,
        )
        .unwrap();

        let notes = db.list_notes_json(Some("b1")).unwrap();
        assert_eq!(notes.len(), 1);
        assert!(notes[0].contains("我的想法"));

        db.upsert_note("n1", "b1", "第一章", "选中片段", "更新内容", 120)
            .unwrap();
        let notes2 = db.list_notes_json(None).unwrap();
        assert!(notes2[0].contains("更新内容"));

        let md = db.export_notes_markdown(Some("b1")).unwrap();
        assert!(md.contains("> 选中片段"));
        assert!(md.contains("更新内容"));

        db.delete_note("n1").unwrap();
        assert!(db.list_notes_json(Some("b1")).unwrap().is_empty());
    }
}
