use super::AppError;
use crate::db;

fn map_database_error<T>(result: Result<T, String>) -> Result<T, AppError> {
    result.map_err(AppError::Database)
}

/// 导出数据库备份 JSON（书架/书源/章节/规则/阅读记录）
#[flutter_rust_bridge::frb(sync)]
pub fn export_backup() -> Result<String, AppError> {
    map_database_error(db::db_export_backup())
}

/// 从备份 JSON 恢复；replace=true 时清空后导入
#[flutter_rust_bridge::frb(sync)]
pub fn restore_backup(json: String, replace: bool) -> Result<(), AppError> {
    map_database_error(db::db_restore_backup(json, replace))
}

#[cfg(test)]
mod tests {
    use super::{map_database_error, AppError};

    #[test]
    fn preserves_database_error_text_and_classification() {
        let message = "备份 JSON 无效: expected value at line 1 column 1".to_string();

        let error = map_database_error::<()>(Err(message.clone())).expect_err("must fail");

        assert!(matches!(error, AppError::Database(ref value) if value == &message));
        assert_eq!(error.to_string(), format!("database: {message}"));
    }

    #[test]
    fn preserves_database_success_value() {
        let backup = r#"{"books":[],"sources":[],"chapters":[]}"#.to_string();

        assert_eq!(map_database_error(Ok(backup.clone())).unwrap(), backup);
    }
}
