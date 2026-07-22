use super::{BookReadingStats, DailyReadingStat, ReadingStats};
use crate::db;
use serde_json::Value;

/// 记录阅读（按书 + 日期累加）
pub fn record_reading(
    book_id: &str,
    book_name: &str,
    chars: i32,
    duration_seconds: i32,
) -> Result<(), String> {
    db::db_record_reading(
        book_id.to_string(),
        book_name.to_string(),
        chars,
        duration_seconds,
    )
}

fn i64_to_i32(v: i64) -> i32 {
    v.clamp(i32::MIN as i64, i32::MAX as i64) as i32
}

fn parse_stats_json(json: &str) -> Result<ReadingStats, String> {
    let v: Value = serde_json::from_str(json).map_err(|e| e.to_string())?;
    let daily = v
        .get("daily")
        .and_then(|d| d.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|item| {
                    Some(DailyReadingStat {
                        date: item.get("date")?.as_str()?.to_string(),
                        chars: i64_to_i32(item.get("chars")?.as_i64()?),
                        duration_seconds: i64_to_i32(item.get("durationSeconds")?.as_i64()?),
                    })
                })
                .collect()
        })
        .unwrap_or_default();

    Ok(ReadingStats {
        total_chars: i64_to_i32(v.get("totalChars").and_then(|x| x.as_i64()).unwrap_or(0)),
        total_duration_seconds: i64_to_i32(
            v.get("totalDurationSeconds")
                .and_then(|x| x.as_i64())
                .unwrap_or(0),
        ),
        today_chars: i64_to_i32(v.get("todayChars").and_then(|x| x.as_i64()).unwrap_or(0)),
        today_duration_seconds: i64_to_i32(
            v.get("todayDurationSeconds")
                .and_then(|x| x.as_i64())
                .unwrap_or(0),
        ),
        week_chars: i64_to_i32(v.get("weekChars").and_then(|x| x.as_i64()).unwrap_or(0)),
        daily,
    })
}

/// 阅读统计
pub fn get_reading_stats(range: &str) -> Result<ReadingStats, String> {
    let json = db::db_get_reading_stats(range.to_string())?;
    parse_stats_json(&json)
}

/// 导出阅读记录（csv / json）
pub fn export_reading_records(format: &str) -> Result<String, String> {
    db::db_export_reading_records(format.to_string())
}

/// 写入详细阅读会话（短会话由数据库层过滤并按同书时间间隔合并）
pub fn record_detailed_read_session(
    book_name: &str,
    start_time: i64,
    end_time: i64,
    read_iteration: i64,
) -> Result<(), String> {
    db::db_record_detailed_read_session(book_name.to_string(), start_time, end_time, read_iteration)
}

/// 导出按书分组的详细阅读会话
pub fn export_detailed_read_records() -> Result<String, String> {
    db::db_export_detailed_read_records()
}

/// 单本书阅读统计
pub fn get_book_reading_stats(book_id: &str) -> Result<BookReadingStats, String> {
    let json = db::db_get_book_reading_stats(book_id.to_string())?;
    let v: Value = serde_json::from_str(&json).map_err(|e| e.to_string())?;
    Ok(BookReadingStats {
        duration_seconds: i64_to_i32(
            v.get("durationSeconds")
                .and_then(|x| x.as_i64())
                .unwrap_or(0),
        ),
        read_chars: i64_to_i32(v.get("readChars").and_then(|x| x.as_i64()).unwrap_or(0)),
        start_date: v
            .get("startDate")
            .and_then(|x| x.as_str())
            .map(str::to_string),
        last_date: v
            .get("lastDate")
            .and_then(|x| x.as_str())
            .map(str::to_string),
        reading_days: i64_to_i32(v.get("readingDays").and_then(|x| x.as_i64()).unwrap_or(0)),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_stats_json_maps_daily_fields() {
        let json = r#"{
            "totalChars": 1000,
            "totalDurationSeconds": 3600,
            "todayChars": 200,
            "todayDurationSeconds": 600,
            "weekChars": 800,
            "daily": [
                {"date":"2026-07-10","chars":500,"durationSeconds":1800},
                {"date":"2026-07-11","chars":200,"durationSeconds":600}
            ]
        }"#;
        let stats = parse_stats_json(json).unwrap();
        assert_eq!(stats.total_chars, 1000);
        assert_eq!(stats.week_chars, 800);
        assert_eq!(stats.daily.len(), 2);
        assert_eq!(stats.daily[1].date, "2026-07-11");
        assert_eq!(stats.daily[1].chars, 200);
    }
}
