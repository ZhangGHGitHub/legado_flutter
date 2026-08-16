import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'legacy_room_import_report.freezed.dart';

/// Kotlin Room 数据库导入结果。
@freezed
class LegacyRoomImportReport with _$LegacyRoomImportReport {
  const LegacyRoomImportReport._();

  const factory LegacyRoomImportReport({
    required int sourceRoomVersion,
    required String fingerprint,
    required bool replaced,
    required bool skippedDuplicate,
    required bool backupWritten,
    required Map<String, int> counts,
    required Map<String, int> conflictCounts,
    required Map<String, int> preservedRows,
    required List<String> warnings,
    required Map<String, List<String>> unmappedColumns,
    @Default(<String>[]) List<String> archiveOnlyTables,
    String? sourceRoomIdentityHash,
    String? backupPath,
  }) = _LegacyRoomImportReport;

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
