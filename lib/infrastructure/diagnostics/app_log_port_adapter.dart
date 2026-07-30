import '../../application/diagnostics/app_log_port.dart';
import '../../domain/diagnostics/diagnostic_record.dart';
import '../../services/app_log.dart';

class AppLogPortAdapter implements AppLogPort {
  const AppLogPortAdapter();

  @override
  List<DiagnosticRecord> get entries =>
      AppLog.entries.map((entry) => entry.record).toList(growable: false);

  @override
  Future<void> ensureLoaded() => AppLog.ensureLoaded();

  @override
  Future<void> i(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) =>
      AppLog.i(message, category: category, source: source, metadata: metadata);

  @override
  Future<void> w(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) =>
      AppLog.w(message, category: category, source: source, metadata: metadata);

  @override
  Future<void> e(
    String message, {
    String category = 'app',
    String? source,
    Map<String, String> metadata = const {},
  }) =>
      AppLog.e(message, category: category, source: source, metadata: metadata);

  @override
  Future<void> clear() => AppLog.clear();

  @override
  String exportText() => entries.map((entry) => entry.line).join('\n');
}
