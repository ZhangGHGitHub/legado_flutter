import 'dart:io';

import '../../domain/remote/webdav_entry.dart';

abstract interface class BackupConfigOperationsPort {
  Future<File> backupToLocalFile();

  Future<void> pickAndRestore();

  Future<void> restoreFromBytes(List<int> bytes);

  Future<void> backupToWebDav();

  Future<List<WebDavEntry>> listWebDavBackups();

  Future<void> restoreFromWebDav(String remotePath);

  Future<void> deleteWebDavBackup(String remotePath);

  Future<void> renameWebDavBackup(String remotePath, String newName);
}
