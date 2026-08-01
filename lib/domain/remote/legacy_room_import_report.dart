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
      sourceRoomVersion: _requiredInt(value, 'sourceRoomVersion'),
      sourceRoomIdentityHash: _optionalString(value, 'sourceRoomIdentityHash'),
      fingerprint: _requiredString(value, 'fingerprint'),
      replaced: _requiredBool(value, 'replaced'),
      skippedDuplicate: _requiredBool(value, 'skippedDuplicate'),
      backupWritten: _requiredBool(value, 'backupWritten'),
      backupPath: _optionalString(value, 'backupPath'),
      counts: _requiredIntMap(value, 'counts'),
      conflictCounts: _requiredIntMap(value, 'conflictCounts'),
      preservedRows: _requiredIntMap(value, 'preservedRows'),
      archiveOnlyTables: _requiredStringList(value, 'archiveOnlyTables'),
      warnings: _requiredStringList(value, 'warnings'),
      unmappedColumns: _requiredStringListMap(value, 'unmappedColumns'),
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

Never _missing(String key) => throw FormatException('Room 导入报告缺少字段: $key');

Object? _required(Map<String, dynamic> value, String key) {
  if (!value.containsKey(key)) {
    _missing(key);
  }
  return value[key];
}

int _requiredInt(Map<String, dynamic> value, String key) {
  final item = _required(value, key);
  if (item is! int) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为 int');
  }
  return item;
}

String _requiredString(Map<String, dynamic> value, String key) {
  final item = _required(value, key);
  if (item is! String) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为 String');
  }
  return item;
}

bool _requiredBool(Map<String, dynamic> value, String key) {
  final item = _required(value, key);
  if (item is! bool) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为 bool');
  }
  return item;
}

String? _optionalString(Map<String, dynamic> value, String key) {
  if (!value.containsKey(key)) return null;
  final item = value[key];
  if (item != null && item is! String) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为 String 或 null');
  }
  return item as String?;
}

List<String> _requiredStringList(Map<String, dynamic> value, String key) {
  final item = _required(value, key);
  if (item is! List || item.any((entry) => entry is! String)) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为 String 数组');
  }
  return item.cast<String>().toList(growable: false);
}

Map<String, int> _requiredIntMap(Map<String, dynamic> value, String key) {
  final item = _required(value, key);
  if (item is! Map ||
      item.keys.any((entry) => entry is! String) ||
      item.values.any((entry) => entry is! int)) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为 String 到 int 的对象');
  }
  return item.map((entry, item) => MapEntry(entry as String, item as int));
}

Map<String, List<String>> _requiredStringListMap(
  Map<String, dynamic> value,
  String key,
) {
  final item = _required(value, key);
  if (item is! Map || item.keys.any((entry) => entry is! String)) {
    throw FormatException('Room 导入报告字段 $key 类型错误，应为字符串数组对象');
  }
  final result = <String, List<String>>{};
  for (final entry in item.entries) {
    final list = entry.value;
    if (list is! List || list.any((value) => value is! String)) {
      throw FormatException('Room 导入报告字段 $key 类型错误，应为字符串数组对象');
    }
    result[entry.key as String] = list.cast<String>().toList(growable: false);
  }
  return result;
}
