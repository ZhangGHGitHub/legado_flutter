import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/database/legacy_room_import_service.dart';
import 'package:legado_flutter/domain/ports/legacy_room_import_port.dart';

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
  test('imports through the application port and parses the report', () {
    final port = _FakeLegacyRoomImportPort();
    final service = LegacyRoomImportService(port);

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
    final service = LegacyRoomImportService(_FakeLegacyRoomImportPort());

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
