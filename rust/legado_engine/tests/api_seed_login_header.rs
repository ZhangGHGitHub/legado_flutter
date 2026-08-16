use legado_engine::{http::login_header_store, seed_login_header, AppError};

#[test]
#[serial_test::serial]
fn seed_login_header_writes_trimmed_value_without_dirty_update() {
    login_header_store::clear();

    let result = seed_login_header(
        "  https://example.com/source  ".to_string(),
        "  {\"Cookie\":\"sid=1\"}  ".to_string(),
    );

    assert!(matches!(result, Ok(())));
    assert_eq!(
        login_header_store::get("https://example.com/source"),
        r#"{"Cookie":"sid=1"}"#
    );
    assert_eq!(login_header_store::drain_dirty_json(), "{}");

    login_header_store::clear();
}

#[test]
#[serial_test::serial]
fn seed_login_header_ignores_empty_source_or_header() {
    login_header_store::clear();

    let empty_source = seed_login_header("   ".to_string(), "{\"Cookie\":\"sid=1\"}".to_string());
    let empty_header =
        seed_login_header("https://example.com/source".to_string(), "   ".to_string());

    assert!(matches!(empty_source, Ok(())));
    assert!(matches!(empty_header, Ok(())));
    assert_eq!(login_header_store::get("https://example.com/source"), "");
    assert_eq!(login_header_store::drain_dirty_json(), "{}");

    login_header_store::clear();
}

#[test]
#[serial_test::serial]
fn seed_login_header_exposes_structured_error_type() {
    fn assert_error_type(_: Result<(), AppError>) {}

    assert_error_type(seed_login_header(String::new(), String::new()));
}
