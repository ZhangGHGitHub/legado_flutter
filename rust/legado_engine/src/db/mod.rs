//! Rust 本地数据库 — 与 Flutter `legado.db` schema v7 对齐（Phase C）

use once_cell::sync::OnceCell;
use rusqlite::{params, Connection};
use serde_json::{json, Value};
use std::sync::Mutex;
use thiserror::Error;

const SCHEMA_VERSION: i32 = 7;

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
               bookSourceName=excluded.bookSourceName, enabled=excluded.enabled,
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
            let raw: String = row.get(0)?;
            if !raw.is_empty() {
                return Ok(raw);
            }
            Ok(json!({
                "bookSourceUrl": row.get::<_, String>(1)?,
                "bookSourceName": row.get::<_, String>(2)?,
                "enabled": row.get::<_, i64>(3)? == 1,
                "bookSourceGroup": row.get::<_, String>(4)?,
                "ruleSearchUrl": row.get::<_, String>(5)?,
            })
            .to_string())
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
            self.conn.execute(
                "INSERT INTO chapters (id, bookId, title, idx, url, isDownloaded, content)
                 VALUES (?1,?2,?3,?4,?5,?6,?7)
                 ON CONFLICT(id) DO UPDATE SET
                   title=excluded.title, idx=excluded.idx, url=excluded.url,
                   isDownloaded=excluded.isDownloaded, content=excluded.content",
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
        let mut stmt = self.conn.prepare(
            "SELECT id, bookId, title, idx, url, isDownloaded, content
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
                "content": row.get::<_, Option<String>>(6)?,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
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
        .unwrap_or_else(|| v.get(key).and_then(|x| x.as_i64()).unwrap_or(0) == 1)
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
}
