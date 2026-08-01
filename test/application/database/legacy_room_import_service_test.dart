import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/legacy_room_import_port.dart';
import 'package:legado_flutter/domain/remote/legacy_room_import_report.dart';
import 'package:legado_flutter/services/legacy_room_import_service_factory.dart';

class _FakeLegacyRoomImportPort implements LegacyRoomImportPort {
  _FakeLegacyRoomImportPort({this.reportJson});

  final String? reportJson;
  String? sourcePath;
  String? backupPath;
  bool? replace;

  @override
  String importDatabase({
    required String sourcePath,
    required String backupPath,
    required bool replace,
  }) {
    this.sourcePath = sourcePath;
    this.backupPath = backupPath;
    this.replace = replace;
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
      "fingerprint": "room-fingerprint-xyz",
      "replaced": true,
      "skippedDuplicate": false,
      "backupWritten": true,
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
    expect(report.fingerprint, 'room-fingerprint-xyz');
    expect(report.replaced, isTrue);
    expect(report.skippedDuplicate, isFalse);
    expect(report.backupWritten, isTrue);
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
      "fingerprint": "room-v99-core-fixture",
      "replaced": true,
      "skippedDuplicate": false,
      "backupWritten": true,
      "counts": {
        "books": 1,
        "book_sources": 1,
        "chapters": 1,
        "bookmarks": 1,
        "readRecord": 1,
        "detailedReadRecord": 1,
        "replace_rules": 1
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
    expect(report.fingerprint, 'room-v99-core-fixture');
    expect(report.replaced, isTrue);
    expect(report.skippedDuplicate, isFalse);
    expect(report.backupWritten, isTrue);
    expect(report.counts, {
      'books': 1,
      'book_sources': 1,
      'chapters': 1,
      'bookmarks': 1,
      'readRecord': 1,
      'detailedReadRecord': 1,
      'replace_rules': 1,
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
        "fingerprint": "room-v99-duplicate",
        "replaced": false,
        "skippedDuplicate": true,
        "backupWritten": true,
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
    expect(report.fingerprint, 'room-v99-duplicate');
    expect(report.replaced, isFalse);
    expect(report.skippedDuplicate, isTrue);
    expect(report.backupWritten, isTrue);
    expect(report.hasWarnings, isFalse);
    expect(report.counts, isEmpty);
    expect(report.conflictCounts, isEmpty);
    expect(report.preservedRows, isEmpty);
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

  test('requires a source and durable backup path', () {
    final service = LegacyRoomImportServices.create(
      _FakeLegacyRoomImportPort(),
    );

    expect(
      () => service.importDatabase(sourcePath: '', backupPath: '/backup.json'),
      throwsArgumentError,
    );
    expect(
      () => service.importDatabase(sourcePath: '/legacy.db', backupPath: ''),
      throwsArgumentError,
    );
  });
}
