import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/bookshelf/remote_archive_import_port.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_sort_port.dart';
import 'package:legado_flutter/application/bookshelf/webdav_prefs_port.dart';
import 'package:legado_flutter/application/diagnostics/app_log_port.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/features/bookshelf/remote_book_page.dart';
import 'package:legado_flutter/infrastructure/diagnostics/app_log_port_adapter.dart';

class _FakeWebDavRepository implements WebDavRepository {
  int ensureDirCalls = 0;
  int listCalls = 0;

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {}

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    ensureDirCalls++;
  }

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    listCalls++;
    return const [];
  }

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async => const [];

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) async {}

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) async {}

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {}

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) async {}
}

final class _FakeArchiveImporter implements RemoteArchiveImportPort {
  @override
  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  }) async => const [];
}

final class _FakeBookSorter implements RemoteBookSortPort {
  @override
  List<WebDavEntry> sort(
    Iterable<WebDavEntry> entries, {
    required RemoteBookSortMode mode,
    required bool ascending,
  }) => entries.toList();
}

final class _FakeWebDavPrefs implements WebDavPrefsPort {
  const _FakeWebDavPrefs();

  @override
  Future<WebDavConfig> load() async => const WebDavConfig(
    url: 'https://example.test/dav',
    account: 'reader',
    password: 'secret',
    dir: '/legado',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uses the injected WebDAV port for initial directory loading', (
    tester,
  ) async {
    final fake = _FakeWebDavRepository();

    await tester.pumpWidget(
      Provider<AppLogPort>.value(
        value: const AppLogPortAdapter(),
        child: MaterialApp(
          home: RemoteBookPage(
            webdavRepository: fake,
            archiveImporter: _FakeArchiveImporter(),
            bookSorter: _FakeBookSorter(),
            webdavPrefs: const _FakeWebDavPrefs(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目录为空'), findsOneWidget);
    expect(fake.ensureDirCalls, 1);
    expect(fake.listCalls, 1);
  });
}
