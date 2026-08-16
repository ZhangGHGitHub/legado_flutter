import '../../src/rust/api/error.dart';

/// Returns the original Rust error text without exposing the Freezed variant.
String? appErrorMessage(Object error) {
  return error is AppError ? error.field0 : null;
}
