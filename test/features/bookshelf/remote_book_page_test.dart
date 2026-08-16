import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/bookshelf/remote_archive_import_port.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_help_port.dart';
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

final class _FakeRemoteBookHelpPort implements RemoteBookHelpPort {
  _FakeRemoteBookHelpPort({this.autoShow = false});

  final bool autoShow;
  int calls = 0;

  @override
  Future<bool> shouldAutoShow() async {
    calls++;
    return autoShow;
  }
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

  testWidgets('opens the original WebDAV book help asset manually', (
    tester,
  ) async {
    final help = _FakeRemoteBookHelpPort();
    await tester.pumpWidget(
      Provider<AppLogPort>.value(
        value: const AppLogPortAdapter(),
        child: MaterialApp(
          home: RemoteBookPage(
            webdavRepository: _FakeWebDavRepository(),
            archiveImporter: _FakeArchiveImporter(),
            bookSorter: _FakeBookSorter(),
            webdavPrefs: const _FakeWebDavPrefs(),
            helpPort: help,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('帮助'));
    await tester.pumpAndSettle();

    expect(find.text('WebDav 书籍简明使用教程'), findsNWidgets(2));
    expect(find.text('上传书籍到 WebDav'), findsOneWidget);
    expect(find.text('坚果云注册与配置 · 语雀 (yuque.com)'), findsOneWidget);
    expect(help.calls, 1);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows WebDAV book help on the original first-open gate', (
    tester,
  ) async {
    final help = _FakeRemoteBookHelpPort(autoShow: true);
    await tester.pumpWidget(
      Provider<AppLogPort>.value(
        value: const AppLogPortAdapter(),
        child: MaterialApp(
          home: RemoteBookPage(
            webdavRepository: _FakeWebDavRepository(),
            archiveImporter: _FakeArchiveImporter(),
            bookSorter: _FakeBookSorter(),
            webdavPrefs: const _FakeWebDavPrefs(),
            helpPort: help,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(help.calls, 1);
    expect(find.text('WebDav 书籍简明使用教程'), findsNWidgets(2));
  });
}
