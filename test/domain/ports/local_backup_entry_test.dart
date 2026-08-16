import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/backup_local_file_port.dart';

void main() {
  group('LocalBackupEntry Freezed contract', () {
    test('preserves the local backup name and path', () {
      const entry = LocalBackupEntry(
        name: 'legado-backup-20260803.zip',
        path: r'C:\\Legado\\backup\\legado-backup-20260803.zip',
      );

      expect(entry.name, 'legado-backup-20260803.zip');
      expect(entry.path, r'C:\\Legado\\backup\\legado-backup-20260803.zip');
    });

    test('uses the local file identity for value equality and copyWith', () {
      const entry = LocalBackupEntry(
        name: 'backup.zip',
        path: '/storage/emulated/0/Legado/backup/backup.zip',
      );
      const sameEntry = LocalBackupEntry(
        name: 'backup.zip',
        path: '/storage/emulated/0/Legado/backup/backup.zip',
      );

      expect(entry, sameEntry);
      expect(
        entry.copyWith(path: '/storage/emulated/0/Download/backup.zip').path,
        '/storage/emulated/0/Download/backup.zip',
      );
    });
  });
}
