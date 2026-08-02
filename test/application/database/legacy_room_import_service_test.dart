import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/legacy_room_import_port.dart';
import 'package:legado_flutter/domain/remote/legacy_room_import_report.dart';
import 'package:legado_flutter/services/legacy_room_import_service_factory.dart';

class _FakeLegacyRoomImportPort implements LegacyRoomImportPort {
  _FakeLegacyRoomImportPort({this.reportJson, this.rejectMissingBackupPath});

  final String? reportJson;
  final bool? rejectMissingBackupPath;
  String? sourcePath;
  String? backupPath;
  bool? replace;

  @override
  String importDatabase({
    required String sourcePath,
    required String? backupPath,
    required bool replace,
  }) {
    this.sourcePath = sourcePath;
    this.backupPath = backupPath;
    this.replace = replace;
    if (rejectMissingBackupPath == true && backupPath == null) {
      throw StateError('Rust rejected a missing backup path');
    }
    return reportJson ??
        '''{
      "sourceRoomVersion": 99,
      "fingerprint": "room-abc",
      "replaced": false,
      "skippedDuplicate": false,
      "backupWritten": true,
      "counts": {"books": 2},
      "conflictCounts": {"books": 1},
      "preservedRows": {"chapters": 3},
      "archiveOnlyTables": ["book_groups"],
      "warnings": ["readRecord deferred"],
      "unmappedColumns": {"chapters": ["wordCount"]}
    }''';
  }
}

void main() {
  test('parses all report collections and fingerprint from JSON', () {
    final report = LegacyRoomImportReport.fromJson('''{
      "sourceRoomVersion": 12,
      "sourceRoomIdentityHash": "room-identity-hash",
      "fingerprint": "room-fingerprint-xyz",
      "replaced": true,
      "skippedDuplicate": false,
      "backupWritten": true,
      "backupPath": "/backup/pre-import.json",
      "counts": {"books": 4, "chapters": 11},
      "conflictCounts": {"books": 2},
      "preservedRows": {"book_groups": 3, "chapters": 7},
      "archiveOnlyTables": ["book_groups", "read_records"],
      "warnings": ["readRecord deferred", "missing optional column"],
      "unmappedColumns": {
        "books": ["customTag", "legacyFlag"],
        "chapters": ["wordCount"]
      }
    }''');

    expect(report.sourceRoomVersion, 12);
    expect(report.sourceRoomIdentityHash, 'room-identity-hash');
    expect(report.fingerprint, 'room-fingerprint-xyz');
    expect(report.replaced, isTrue);
    expect(report.skippedDuplicate, isFalse);
    expect(report.backupWritten, isTrue);
    expect(report.backupPath, '/backup/pre-import.json');
    expect(report.counts, {'books': 4, 'chapters': 11});
    expect(report.conflictCounts, {'books': 2});
    expect(report.preservedRows, {'book_groups': 3, 'chapters': 7});
    expect(report.archiveOnlyTables, ['book_groups', 'read_records']);
    expect(report.warnings, ['readRecord deferred', 'missing optional column']);
    expect(report.unmappedColumns, {
      'books': ['customTag', 'legacyFlag'],
      'chapters': ['wordCount'],
    });
  });

  test('preserves the Room migration evidence for all mapped core tables', () {
    final report = LegacyRoomImportReport.fromJson('''{
      "sourceRoomVersion": 99,
      "sourceRoomIdentityHash": "room-v99-identity-hash",
      "fingerprint": "room-v99-core-fixture",
      "replaced": true,
      "skippedDuplicate": false,
      "backupWritten": true,
      "counts": {
        "books": 1,
        "sources": 1,
        "chapters": 1,
        "bookmarks": 1,
        "readRecord": 1,
        "detailedReadRecords": 1,
        "replaceRules": 1
      },
      "conflictCounts": {},
      "preservedRows": {
        "books": 1,
        "book_sources": 1,
        "chapters": 1,
        "bookmarks": 1,
        "detailedReadRecord": 1,
        "replace_rules": 1,
        "readRecord": 1
      },
      "archiveOnlyTables": ["book_groups"],
      "warnings": [
        "readRecord contains aggregate readTime/lastRead without stable bookUrl/date"
      ],
      "unmappedColumns": {
        "books": ["originName"],
        "chapters": ["wordCount"],
        "replace_rules": ["sortOrder", "scope", "group"]
      }
    }''');

    expect(report.sourceRoomVersion, 99);
    expect(report.sourceRoomIdentityHash, 'room-v99-identity-hash');
    expect(report.fingerprint, 'room-v99-core-fixture');
    expect(report.replaced, isTrue);
    expect(report.skippedDuplicate, isFalse);
    expect(report.backupWritten, isTrue);
    expect(report.counts, {
      'books': 1,
      'sources': 1,
      'chapters': 1,
      'bookmarks': 1,
      'readRecord': 1,
      'detailedReadRecords': 1,
      'replaceRules': 1,
    });
    expect(report.conflictCounts, isEmpty);
    expect(report.preservedRows, {
      'books': 1,
      'book_sources': 1,
      'chapters': 1,
      'bookmarks': 1,
      'detailedReadRecord': 1,
      'replace_rules': 1,
      'readRecord': 1,
    });
    expect(report.archiveOnlyTables, ['book_groups']);
    expect(report.warnings, [
      'readRecord contains aggregate readTime/lastRead without stable bookUrl/date',
    ]);
    expect(report.unmappedColumns, {
      'books': ['originName'],
      'chapters': ['wordCount'],
      'replace_rules': ['sortOrder', 'scope', 'group'],
    });
    expect(report.hasWarnings, isTrue);
  });

  test('reports duplicate import without losing backup or source identity', () {
    final port = _FakeLegacyRoomImportPort(
      reportJson: '''{
      "sourceRoomVersion": 99,
        "sourceRoomIdentityHash": "room-v99-duplicate-identity-hash",
        "fingerprint": "room-v99-duplicate",
        "replaced": false,
        "skippedDuplicate": true,
        "backupPath": "/backup/pre-import.json",
        "backupWritten": false,
        "counts": {},
        "conflictCounts": {},
        "preservedRows": {},
        "archiveOnlyTables": [],
        "warnings": [],
        "unmappedColumns": {}
      }''',
    );
    final service = LegacyRoomImportServices.create(port);

    final report = service.importDatabase(
      sourcePath: '/legacy/legado.db',
      backupPath: '/backup/pre-import.json',
    );

    expect(report.sourceRoomVersion, 99);
    expect(report.sourceRoomIdentityHash, 'room-v99-duplicate-identity-hash');
    expect(report.fingerprint, 'room-v99-duplicate');
    expect(report.replaced, isFalse);
    expect(report.skippedDuplicate, isTrue);
    expect(report.backupWritten, isFalse);
    expect(report.backupPath, '/backup/pre-import.json');
    expect(report.hasWarnings, isFalse);
    expect(report.counts, isEmpty);
    expect(report.conflictCounts, isEmpty);
    expect(report.preservedRows, isEmpty);
    expect(report.archiveOnlyTables, isEmpty);
    expect(report.warnings, isEmpty);
    expect(report.unmappedColumns, isEmpty);
  });

  test('forwards a null backup path for duplicate imports', () {
    final port = _FakeLegacyRoomImportPort(
      reportJson: '''{
        "sourceRoomVersion": 99,
        "sourceRoomIdentityHash": "room-v99-null-backup-identity-hash",
        "fingerprint": "room-v99-null-backup",
        "replaced": false,
        "skippedDuplicate": true,
        "backupPath": null,
        "backupWritten": false,
        "counts": {},
        "conflictCounts": {},
        "preservedRows": {},
        "archiveOnlyTables": [],
        "warnings": [],
        "unmappedColumns": {}
      }''',
    );
    final service = LegacyRoomImportServices.create(port);

    final report = service.importDatabase(
      sourcePath: '/legacy/legado.db',
      backupPath: null,
      replace: false,
    );

    expect(port.sourcePath, '/legacy/legado.db');
    expect(port.backupPath, isNull);
    expect(port.replace, isFalse);
    expect(report.sourceRoomIdentityHash, 'room-v99-null-backup-identity-hash');
    expect(report.fingerprint, 'room-v99-null-backup');
    expect(report.skippedDuplicate, isTrue);
    expect(report.backupPath, isNull);
    expect(report.backupWritten, isFalse);
    expect(report.counts, isEmpty);
    expect(report.conflictCounts, isEmpty);
    expect(report.preservedRows, isEmpty);
    expect(report.archiveOnlyTables, isEmpty);
    expect(report.warnings, isEmpty);
    expect(report.unmappedColumns, isEmpty);
  });

  test(
    'ignores unknown report fields without changing the supported contract',
    () {
      final report = LegacyRoomImportReport.fromJson('''{
      "sourceRoomVersion": 99,
      "fingerprint": "room-v99-unknown-field",
      "replaced": false,
      "skippedDuplicate": false,
      "backupWritten": true,
      "counts": {"books": 1},
      "conflictCounts": {},
      "preservedRows": {"books": 1},
      "archiveOnlyTables": [],
      "warnings": [],
      "unmappedColumns": {},
      "futureReportField": {"unsupported": true},
      "unknownCollection": ["ignored"]
    }''');

      expect(report.sourceRoomVersion, 99);
      expect(report.sourceRoomIdentityHash, isNull);
      expect(report.fingerprint, 'room-v99-unknown-field');
      expect(report.replaced, isFalse);
      expect(report.skippedDuplicate, isFalse);
      expect(report.backupWritten, isTrue);
      expect(report.backupPath, isNull);
      expect(report.counts, {'books': 1});
      expect(report.conflictCounts, isEmpty);
      expect(report.preservedRows, {'books': 1});
      expect(report.archiveOnlyTables, isEmpty);
      expect(report.warnings, isEmpty);
      expect(report.unmappedColumns, isEmpty);
      expect(report.hasWarnings, isFalse);
    },
  );

  test('accepts omitted optional identity and backup fields', () {
    final report = LegacyRoomImportReport.fromJson('''{
      "sourceRoomVersion": 99,
      "fingerprint": "room-v99-optional-fields",
      "replaced": false,
      "skippedDuplicate": false,
      "backupWritten": false,
      "counts": {},
      "conflictCounts": {},
      "preservedRows": {},
      "archiveOnlyTables": [],
      "warnings": [],
      "unmappedColumns": {}
    }''');

    expect(report.sourceRoomIdentityHash, isNull);
    expect(report.backupPath, isNull);
  });

  test('matches the complete Rust serde report shape on both import paths', () {
    const expectedKeys = <String>{
      'sourceRoomVersion',
      'sourceRoomIdentityHash',
      'fingerprint',
      'replaced',
      'skippedDuplicate',
      'backupPath',
      'backupWritten',
      'counts',
      'conflictCounts',
      'preservedRows',
      'archiveOnlyTables',
      'warnings',
      'unmappedColumns',
    };
    const rustReportPayloads = [
      '''{
        "sourceRoomVersion": 99,
        "sourceRoomIdentityHash": "room-v99-success-identity",
        "fingerprint": "room-v99-success",
        "replaced": false,
        "skippedDuplicate": false,
        "backupPath": "/backup/pre-import.json",
        "backupWritten": true,
        "counts": {"books": 1},
        "conflictCounts": {},
        "preservedRows": {"books": 1},
        "archiveOnlyTables": ["book_groups"],
        "warnings": ["readRecord deferred"],
        "unmappedColumns": {"chapters": ["wordCount"]}
      }''',
      '''{
        "sourceRoomVersion": 99,
        "sourceRoomIdentityHash": "room-v99-duplicate-identity",
        "fingerprint": "room-v99-duplicate",
        "replaced": false,
        "skippedDuplicate": true,
        "backupPath": null,
        "backupWritten": false,
        "counts": {"books": 1},
        "conflictCounts": {},
        "preservedRows": {"books": 1},
        "archiveOnlyTables": ["book_groups"],
        "warnings": ["legacy Room snapshot already imported; skipped duplicate"],
        "unmappedColumns": {"chapters": ["wordCount"]}
      }''',
    ];

    for (final raw in rustReportPayloads) {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      expect(payload.keys.toSet(), expectedKeys);
      expect(payload['sourceRoomVersion'], isA<int>());
      expect(payload['sourceRoomIdentityHash'], anyOf(isA<String>(), isNull));
      expect(payload['fingerprint'], isA<String>());
      expect(payload['replaced'], isA<bool>());
      expect(payload['skippedDuplicate'], isA<bool>());
      expect(payload['backupPath'], anyOf(isA<String>(), isNull));
      expect(payload['backupWritten'], isA<bool>());
      expect(payload['counts'], isA<Map<String, dynamic>>());
      expect(payload['conflictCounts'], isA<Map<String, dynamic>>());
      expect(payload['preservedRows'], isA<Map<String, dynamic>>());
      expect(payload['archiveOnlyTables'], isA<List<dynamic>>());
      expect(payload['warnings'], isA<List<dynamic>>());
      expect(payload['unmappedColumns'], isA<Map<String, dynamic>>());

      final report = LegacyRoomImportReport.fromJson(raw);
      expect(report.sourceRoomVersion, 99);
      expect(report.sourceRoomIdentityHash, isNotNull);
      expect(report.fingerprint, isNotEmpty);
      expect(report.backupPath, anyOf(isA<String>(), isNull));
      expect(report.counts, {'books': 1});
      expect(report.conflictCounts, isEmpty);
      expect(report.preservedRows, {'books': 1});
      expect(report.archiveOnlyTables, ['book_groups']);
      expect(report.warnings, isNotEmpty);
      expect(report.unmappedColumns, {
        'chapters': ['wordCount'],
      });
    }
  });

  test('rejects missing required report fields', () {
    const requiredFields = [
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
    ];
    const completeReport = <String, Object>{
      'sourceRoomVersion': 99,
      'fingerprint': 'room-v99-required-fields',
      'replaced': false,
      'skippedDuplicate': false,
      'backupWritten': false,
      'counts': <String, int>{},
      'conflictCounts': <String, int>{},
      'preservedRows': <String, int>{},
      'archiveOnlyTables': <String>[],
      'warnings': <String>[],
      'unmappedColumns': <String, List<String>>{},
    };

    for (final field in requiredFields) {
      final report = Map<String, Object>.from(completeReport)..remove(field);
      expect(
        () => LegacyRoomImportReport.fromJson(jsonEncode(report)),
        throwsFormatException,
        reason: '字段 $field 缺失时必须失败',
      );
    }
  });

  test('rejects invalid required report field types', () {
    const validReport = <String, Object>{
      'sourceRoomVersion': 99,
      'fingerprint': 'room-v99-invalid-types',
      'replaced': false,
      'skippedDuplicate': false,
      'backupWritten': false,
      'counts': <String, int>{'books': 1},
      'conflictCounts': <String, int>{},
      'preservedRows': <String, int>{},
      'archiveOnlyTables': <String>[],
      'warnings': <String>[],
      'unmappedColumns': <String, List<String>>{},
    };
    final invalidValues = <String, Object>{
      'sourceRoomVersion': '99',
      'fingerprint': 99,
      'replaced': 'false',
      'skippedDuplicate': 0,
      'backupWritten': 'false',
      'counts': [],
      'conflictCounts': {'books': '1'},
      'preservedRows': {'books': 1.0},
      'archiveOnlyTables': [1],
      'warnings': [null],
      'unmappedColumns': {'books': 'originName'},
    };

    for (final entry in invalidValues.entries) {
      final report = Map<String, Object>.from(validReport)
        ..[entry.key] = entry.value;
      expect(
        () => LegacyRoomImportReport.fromJson(jsonEncode(report)),
        throwsFormatException,
        reason: '字段 ${entry.key} 类型错误时必须失败',
      );
    }
  });

  test('rejects invalid types for present optional report fields', () {
    const validReport = <String, Object>{
      'sourceRoomVersion': 99,
      'fingerprint': 'room-v99-invalid-optional-types',
      'replaced': false,
      'skippedDuplicate': false,
      'backupWritten': false,
      'counts': <String, int>{},
      'conflictCounts': <String, int>{},
      'preservedRows': <String, int>{},
      'archiveOnlyTables': <String>[],
      'warnings': <String>[],
      'unmappedColumns': <String, List<String>>{},
    };

    for (final entry in <String, Object>{
      'sourceRoomIdentityHash': 99,
      'backupPath': false,
    }.entries) {
      final report = Map<String, Object>.from(validReport)
        ..[entry.key] = entry.value;
      expect(
        () => LegacyRoomImportReport.fromJson(jsonEncode(report)),
        throwsFormatException,
        reason: '可选字段 ${entry.key} 存在但类型错误时必须失败',
      );
    }
  });

  test('imports through the application port and parses the report', () {
    final port = _FakeLegacyRoomImportPort();
    final service = LegacyRoomImportServices.create(port);

    final report = service.importDatabase(
      sourcePath: '/legacy/legado.db',
      backupPath: '/backup/pre-import.json',
      replace: true,
    );

    expect(port.sourcePath, '/legacy/legado.db');
    expect(port.backupPath, '/backup/pre-import.json');
    expect(port.replace, isTrue);
    expect(report.sourceRoomVersion, 99);
    expect(report.counts['books'], 2);
    expect(report.conflictCounts['books'], 1);
    expect(report.preservedRows['chapters'], 3);
    expect(report.archiveOnlyTables, ["book_groups"]);
    expect(report.hasWarnings, isTrue);
  });

  test(
    'requires a source and leaves missing backup path validation to Rust',
    () {
      final port = _FakeLegacyRoomImportPort(rejectMissingBackupPath: true);
      final service = LegacyRoomImportServices.create(port);

      expect(
        () =>
            service.importDatabase(sourcePath: '', backupPath: '/backup.json'),
        throwsArgumentError,
      );

      expect(
        () =>
            service.importDatabase(sourcePath: '/legacy.db', backupPath: null),
        throwsStateError,
      );
      expect(port.sourcePath, '/legacy.db');
      expect(port.backupPath, isNull);
      expect(port.replace, isFalse);
    },
  );
}
