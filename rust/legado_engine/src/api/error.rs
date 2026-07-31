use thiserror::Error;

/// Structured error boundary for public Flutter API migration.
#[derive(Debug, Clone, Error)]
pub enum AppError {
    #[error("network: {0}")]
    Network(String),
    #[error("parse: {0}")]
    Parse(String),
    #[error("database: {0}")]
    Database(String),
    #[error("javascript execution: {0}")]
    JsExecution(String),
    #[error("validation: {0}")]
    Validation(String),
    #[error("unsupported: {0}")]
    Unsupported(String),
    #[error("cancelled: {0}")]
    Cancelled(String),
    #[error("unknown: {0}")]
    Unknown(String),
}

impl AppError {
    pub(crate) fn from_legacy(message: String) -> Self {
        let lower = message.to_ascii_lowercase();
        if lower.contains("http")
            || lower.contains("network")
            || lower.contains("连接")
            || lower.contains("请求")
        {
            return Self::Network(message);
        }
        if lower.contains("json")
            || lower.contains("parse")
            || lower.contains("解析")
            || lower.contains("规则")
        {
            return Self::Parse(message);
        }
        if lower.contains("javascript") || lower.contains("js ") || lower.contains("quickjs") {
            return Self::JsExecution(message);
        }
        Self::Unknown(message)
    }
}
