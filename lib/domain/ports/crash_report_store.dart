import '../crash/crash_report.dart';

abstract interface class CrashReportStore {
  Future<CrashReport?> readLatest();

  Future<CrashReport?> readPending();

  Future<void> writePending(CrashReport report);

  Future<void> acknowledgePending();

  Future<void> clear();
}
