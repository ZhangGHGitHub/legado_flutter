import '../../domain/diagnostics/diagnostic_record.dart';

abstract interface class AppLogPort {
  List<DiagnosticRecord> get entries;

  Future<void> ensureLoaded();
  Future<void> clear();
  String exportText();
}
