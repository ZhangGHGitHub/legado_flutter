//! Rust 侧本地数据库（Phase D.3 脚手架，后续对齐 Legado 书架/书源表）

use rusqlite::{Connection, params};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("sqlite: {0}")]
    Sqlite(#[from] rusqlite::Error),
    #[error("{0}")]
    Message(String),
}

/// 引擎本地 SQLite（与 Flutter sqflite 并行，供 Rust 侧缓存/离线能力扩展）
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
             PRAGMA user_version = 1;
             CREATE TABLE IF NOT EXISTS books (
               id TEXT PRIMARY KEY,
               name TEXT NOT NULL,
               author TEXT DEFAULT '',
               book_url TEXT DEFAULT '',
               source_url TEXT DEFAULT '',
               updated_at INTEGER DEFAULT (strftime('%s','now'))
             );
             CREATE TABLE IF NOT EXISTS chapters (
               id TEXT PRIMARY KEY,
               book_id TEXT NOT NULL,
               title TEXT NOT NULL,
               url TEXT NOT NULL,
               idx INTEGER NOT NULL,
               FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
             );",
        )?;
        Ok(())
    }

    pub fn schema_version(&self) -> Result<i32, DbError> {
        Ok(self.conn.query_row("PRAGMA user_version", [], |r| r.get(0))?)
    }

    pub fn upsert_book(
        &self,
        id: &str,
        name: &str,
        author: &str,
        book_url: &str,
        source_url: &str,
    ) -> Result<(), DbError> {
        self.conn.execute(
            "INSERT INTO books (id, name, author, book_url, source_url)
             VALUES (?1, ?2, ?3, ?4, ?5)
             ON CONFLICT(id) DO UPDATE SET
               name = excluded.name,
               author = excluded.author,
               book_url = excluded.book_url,
               source_url = excluded.source_url,
               updated_at = strftime('%s','now')",
            params![id, name, author, book_url, source_url],
        )?;
        Ok(())
    }

    pub fn book_count(&self) -> Result<i64, DbError> {
        Ok(self
            .conn
            .query_row("SELECT COUNT(*) FROM books", [], |r| r.get(0))?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn in_memory_db_schema_and_upsert() {
        let db = EngineDb::open_in_memory().unwrap();
        assert_eq!(db.schema_version().unwrap(), 1);
        db.upsert_book("b1", "斗破", "土豆", "http://x/book/1", "http://src")
            .unwrap();
        assert_eq!(db.book_count().unwrap(), 1);
    }
}
