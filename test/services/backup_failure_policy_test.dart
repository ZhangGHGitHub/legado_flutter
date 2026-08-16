import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/settings/backup_config_page.dart';

void main() {
  test(
    'permission failures preserve the local backup and operation context',
    () {
      expect(
        backupOperationErrorMessage(
          StateError('HTTP 401 Unauthorized'),
          operation: BackupOperation.upload,
        ),
        contains('本地备份仍保留'),
      );
      expect(
        backupOperationErrorMessage(
          StateError('HTTP 403 Forbidden'),
          operation: BackupOperation.restore,
        ),
        contains('当前数据未修改'),
      );
    },
  );

  test('unsupported WebDAV methods preserve the remote backup', () {
    expect(
      backupOperationErrorMessage(
        StateError('HTTP 405 Method Not Allowed'),
        operation: BackupOperation.delete,
      ),
      contains('原备份未删除'),
    );
    expect(
      backupOperationErrorMessage(
        StateError('HTTP 501 Not Implemented'),
        operation: BackupOperation.rename,
      ),
      contains('原备份未删除'),
    );
  });

  test(
    'not-found failures remain visible instead of being treated as success',
    () {
      expect(
        backupOperationErrorMessage(
          StateError('HTTP 404 Not Found'),
          operation: BackupOperation.restore,
        ),
        contains('HTTP 404'),
      );
    },
  );
}
