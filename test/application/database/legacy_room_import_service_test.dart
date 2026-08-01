import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/legacy_room_import_port.dart';
import 'package:legado_flutter/domain/remote/legacy_room_import_report.dart';
import 'package:legado_flutter/services/legacy_room_import_service_factory.dart';

class _FakeLegacyRoomImportPort implements LegacyRoomImportPort {
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
    return '''{
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
