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
  Future<void> clear() => AppLog.clear();

  @override
  String exportText() => entries.map((entry) => entry.line).join('\n');
}
