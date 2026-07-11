use crate::db;

/// 导出数据库备份 JSON（书架/书源/章节/规则/阅读记录）
#[flutter_rust_bridge::frb(sync)]
pub fn export_backup() -> Result<String, String> {
    db::db_export_backup()
}

/// 从备份 JSON 恢复；replace=true 时清空后导入
#[flutter_rust_bridge::frb(sync)]
pub fn restore_backup(json: String, replace: bool) -> Result<(), String> {
    db::db_restore_backup(json, replace)
}
