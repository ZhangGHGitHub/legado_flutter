import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/remote/legacy_room_import_report.dart';

Map<String, dynamic> _baseJson() => {
  'sourceRoomVersion': 99,
  'sourceRoomIdentityHash': 'room-hash',
  'fingerprint': 'fingerprint',
  'replaced': true,
  'skippedDuplicate': false,
  'backupWritten': true,
  'backupPath': 'backup.json',
  'counts': {'books': 2, 'chapters': 4},
  'conflictCounts': {'books': 1},
  'preservedRows': {'chapters': 3},
  'archiveOnlyTables': ['readRecord'],
  'warnings': <String>[],
  'unmappedColumns': <String, List<String>>{
    'chapters': ['extraColumn'],
  },
};

void main() {
  group('LegacyRoomImportReport', () {
    test('保留 JSON 字段并支持未知字段', () {
      final report = LegacyRoomImportReport.fromJson(
        jsonEncode({..._baseJson(), 'futureField': 'ignored'}),
      );

      expect(report.sourceRoomVersion, 99);
      expect(report.sourceRoomIdentityHash, 'room-hash');
      expect(report.fingerprint, 'fingerprint');
      expect(report.replaced, isTrue);
      expect(report.skippedDuplicate, isFalse);
      expect(report.backupWritten, isTrue);
      expect(report.backupPath, 'backup.json');
      expect(report.counts, {'books': 2, 'chapters': 4});
      expect(report.conflictCounts, {'books': 1});
      expect(report.preservedRows, {'chapters': 3});
      expect(report.archiveOnlyTables, ['readRecord']);
      expect(report.warnings, isEmpty);
      expect(report.unmappedColumns, {
        'chapters': ['extraColumn'],
      });
      expect(report.hasWarnings, isTrue);
    });

    test('可选字段缺失时保持兼容', () {
      final json = _baseJson()
        ..remove('sourceRoomIdentityHash')
        ..remove('backupPath');

      final report = LegacyRoomImportReport.fromJson(jsonEncode(json));

      expect(report.sourceRoomIdentityHash, isNull);
      expect(report.backupPath, isNull);
    });

    test('无 warning 且无未映射列时 hasWarnings 为 false', () {
      final json = _baseJson()
        ..['warnings'] = <String>[]
        ..['unmappedColumns'] = <String, List<String>>{};

      final report = LegacyRoomImportReport.fromJson(jsonEncode(json));

      expect(report.hasWarnings, isFalse);
    });

    test('Freezed 保留值对象语义和 copyWith', () {
      final report = LegacyRoomImportReport.fromJson(jsonEncode(_baseJson()));
      final copied = report.copyWith(fingerprint: 'next');

      expect(copied, isNot(equals(report)));
      expect(copied.fingerprint, 'next');
      expect(copied.sourceRoomVersion, report.sourceRoomVersion);
      expect(
        report,
        equals(LegacyRoomImportReport.fromJson(jsonEncode(_baseJson()))),
      );
    });

    test('非对象 JSON 保留中文错误原文', () {
      expect(
        () => LegacyRoomImportReport.fromJson('[]'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Room 导入报告不是 JSON 对象',
          ),
        ),
      );
    });

    for (final key in [
      'sourceRoomVersion',
      'fingerprint',
      'replaced',
      'skippedDuplicate',
      'backupWritten',
      'counts',
      'conflictCounts',
      'preservedRows',
      'archiveOnlyTables',
      'warnings',
      'unmappedColumns',
    ]) {
      test('必需字段 $key 缺失时拒绝', () {
        final json = _baseJson()..remove(key);

        expect(
          () => LegacyRoomImportReport.fromJson(jsonEncode(json)),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'Room 导入报告缺少字段: $key',
            ),
          ),
        );
      });
    }

    final requiredTypeCases = <String, dynamic>{
      'sourceRoomVersion': '99',
      'fingerprint': 99,
      'replaced': 'true',
      'skippedDuplicate': 0,
      'backupWritten': 'true',
      'archiveOnlyTables': [1],
      'warnings': [false],
    };
    for (final entry in requiredTypeCases.entries) {
      test('必需字段 ${entry.key} 类型错误时拒绝', () {
        final json = _baseJson()..[entry.key] = entry.value;

        expect(
          () => LegacyRoomImportReport.fromJson(jsonEncode(json)),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('Room 导入报告字段 ${entry.key} 类型错误'),
            ),
          ),
        );
      });
    }

    for (final key in ['sourceRoomIdentityHash', 'backupPath']) {
      test('可选字段 $key 类型错误时拒绝', () {
        final json = _baseJson()..[key] = 1;

        expect(
          () => LegacyRoomImportReport.fromJson(jsonEncode(json)),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'Room 导入报告字段 $key 类型错误，应为 String 或 null',
            ),
          ),
        );
      });
    }

    for (final key in ['counts', 'conflictCounts', 'preservedRows']) {
      test('$key 的键和值类型错误时拒绝', () {
        final json = _baseJson()..[key] = {'books': '1'};

        expect(
          () => LegacyRoomImportReport.fromJson(jsonEncode(json)),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'Room 导入报告字段 $key 类型错误，应为 String 到 int 的对象',
            ),
          ),
        );
      });
    }

    test('unmappedColumns 必须是字符串数组对象', () {
      final json = _baseJson()
        ..['unmappedColumns'] = {
          'chapters': [1],
        };

      expect(
        () => LegacyRoomImportReport.fromJson(jsonEncode(json)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Room 导入报告字段 unmappedColumns 类型错误，应为字符串数组对象',
          ),
        ),
      );
    });
  });
}
