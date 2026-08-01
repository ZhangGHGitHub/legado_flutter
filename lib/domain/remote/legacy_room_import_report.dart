import 'dart:convert';

/// Kotlin Room 数据库导入结果。
class LegacyRoomImportReport {
  const LegacyRoomImportReport({
    required this.sourceRoomVersion,
    required this.fingerprint,
    required this.replaced,
    required this.skippedDuplicate,
    required this.backupWritten,
    required this.counts,
    required this.conflictCounts,
    required this.preservedRows,
    required this.warnings,
    required this.unmappedColumns,
    this.archiveOnlyTables = const [],
    this.sourceRoomIdentityHash,
    this.backupPath,
  });

  factory LegacyRoomImportReport.fromJson(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Room 导入报告不是 JSON 对象');
    }
    return LegacyRoomImportReport(
      sourceRoomVersion: _int(value['sourceRoomVersion']),
      sourceRoomIdentityHash: _nullableString(value['sourceRoomIdentityHash']),
      fingerprint: _string(value['fingerprint']),
      replaced: value['replaced'] == true,
      skippedDuplicate: value['skippedDuplicate'] == true,
      backupWritten: value['backupWritten'] == true,
      backupPath: _nullableString(value['backupPath']),
      counts: _intMap(value['counts']),
      conflictCounts: _intMap(value['conflictCounts']),
      preservedRows: _intMap(value['preservedRows']),
      archiveOnlyTables: _stringList(value['archiveOnlyTables']),
      warnings: _stringList(value['warnings']),
      unmappedColumns: _stringListMap(value['unmappedColumns']),
    );
  }

  final int sourceRoomVersion;
  final String? sourceRoomIdentityHash;
  final String fingerprint;
  final bool replaced;
  final bool skippedDuplicate;
  final bool backupWritten;
  final String? backupPath;
  final Map<String, int> counts;
  final Map<String, int> conflictCounts;
  final Map<String, int> preservedRows;
  final List<String> archiveOnlyTables;
  final List<String> warnings;
  final Map<String, List<String>> unmappedColumns;

  bool get hasWarnings => warnings.isNotEmpty || unmappedColumns.isNotEmpty;
}

int _int(Object? value) => value is num ? value.toInt() : 0;

String _string(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) => value is String ? value : null;

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), _int(item)));
}

Map<String, List<String>> _stringListMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), _stringList(item)));
}
