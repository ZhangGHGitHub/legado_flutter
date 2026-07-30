import '../../domain/diagnostics/diagnostic_record.dart';

abstract interface class AppLogPort {
  List<DiagnosticRecord> get entries;

  Future<void> ensureLoaded();
  Future<void> i(
    String message, {
    String category,
    String? source,
    Map<String, String> metadata,
  });
  Future<void> w(
    String message, {
    String category,
    String? source,
    Map<String, String> metadata,
  });
  Future<void> e(
    String message, {
    String category,
    String? source,
    Map<String, String> metadata,
  });
  Future<void> clear();
  String exportText();
}
