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

#[cfg(test)]
mod tests {
    use super::AppError;

    #[test]
    fn classifies_network_and_http_errors() {
        let message = "HTTP 503: network request failed".to_string();

        let error = AppError::from_legacy(message.clone());

        assert!(matches!(error, AppError::Network(ref value) if value == &message));
        assert_eq!(
            error.to_string(),
            "network: HTTP 503: network request failed"
        );
    }

    #[test]
    fn classifies_parse_and_json_errors() {
        let message = "invalid JSON response".to_string();

        let error = AppError::from_legacy(message.clone());

        assert!(matches!(error, AppError::Parse(ref value) if value == &message));
        assert_eq!(error.to_string(), "parse: invalid JSON response");
    }

    #[test]
    fn classifies_javascript_and_quickjs_errors() {
        let message = "QuickJS execution failed".to_string();

        let error = AppError::from_legacy(message.clone());

        assert!(matches!(error, AppError::JsExecution(ref value) if value == &message));
        assert_eq!(
            error.to_string(),
            "javascript execution: QuickJS execution failed"
        );
    }

    #[test]
    fn classifies_unrecognized_text_as_unknown() {
        let message = "unexpected source failure".to_string();

        let error = AppError::from_legacy(message.clone());

        assert!(matches!(error, AppError::Unknown(ref value) if value == &message));
        assert_eq!(error.to_string(), "unknown: unexpected source failure");
    }
}
