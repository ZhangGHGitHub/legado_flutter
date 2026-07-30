import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uses the injected WebDAV port for initial directory loading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://example.test/dav',
      'webdav_account': 'reader',
      'webdav_password': 'secret',
      'webdav_dir': '/legado',
    });
    final fake = _FakeWebDavRepository();

    await tester.pumpWidget(
      Provider<AppLogPort>.value(
        value: const AppLogPortAdapter(),
        child: MaterialApp(home: RemoteBookPage(webdavRepository: fake)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目录为空'), findsOneWidget);
    expect(fake.ensureDirCalls, 1);
    expect(fake.listCalls, 1);
  });
}
