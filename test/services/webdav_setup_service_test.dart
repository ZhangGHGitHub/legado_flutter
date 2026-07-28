import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:legado_flutter/services/webdav_setup_service.dart';

class _FakeWebDavRepository implements WebDavRepository {
  final calls = <String>[];
  Object? checkError;
  Object? ensureDirError;

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    calls.add('check:$url:$username:$password:$path');
    if (checkError != null) throw checkError!;
  }

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    calls.add('mkdir:$url:$username:$password:$path');
    if (ensureDirError != null) throw ensureDirError!;
  }

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) => throw UnimplementedError();

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) => throw UnimplementedError();

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) => throw UnimplementedError();

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) => throw UnimplementedError();

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) => throw UnimplementedError();

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) => throw UnimplementedError();
}

void main() {
  test('initializes the root and original WebDAV directories in order', () async {
    const config = WebDavConfig(
      url: 'https://dav.example.com/dav',
      account: 'account',
      password: 'password',
      dir: '/legado',
    );
    final calls = <String>[];

    Future<void> check({
      required String url,
      required String username,
      required String password,
      required String path,
    }) async {
      calls.add('check:$url:$username:$password:$path');
    }

    Future<void> ensureDir({
      required String url,
      required String username,
      required String password,
      required String path,
    }) async {
      calls.add('mkdir:$url:$username:$password:$path');
    }

    await WebDavSetupService.initialize(
      config,
      check: check,
      ensureDir: ensureDir,
    );

    expect(calls, [
      'check:https://dav.example.com/dav:account:password:/legado',
      'mkdir:https://dav.example.com/dav:account:password:/legado',
      'mkdir:https://dav.example.com/dav:account:password:/legado/bookProgress',
      'mkdir:https://dav.example.com/dav:account:password:/legado/books',
      'mkdir:https://dav.example.com/dav:account:password:/legado/background',
    ]);
  });

  test('uses the repository port for production-shaped setup', () async {
    const config = WebDavConfig(
      url: 'https://dav.example.com/dav',
      account: 'account',
      password: 'password',
      dir: '/legado',
    );
    final repository = _FakeWebDavRepository();

    await WebDavSetupService.initialize(config, repository: repository);

    expect(repository.calls, [
      'check:https://dav.example.com/dav:account:password:/legado',
      'mkdir:https://dav.example.com/dav:account:password:/legado',
      'mkdir:https://dav.example.com/dav:account:password:/legado/bookProgress',
      'mkdir:https://dav.example.com/dav:account:password:/legado/books',
      'mkdir:https://dav.example.com/dav:account:password:/legado/background',
    ]);
  });

  test(
    'propagates repository errors and stops subsequent directory setup',
    () async {
      const config = WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
      );
      final repository = _FakeWebDavRepository()
        ..ensureDirError = StateError('offline');

      await expectLater(
        WebDavSetupService.initialize(config, repository: repository),
        throwsA(isA<StateError>()),
      );
      expect(repository.calls, [
        'check:https://dav.example.com/dav:account:password:/legado',
        'mkdir:https://dav.example.com/dav:account:password:/legado',
      ]);
    },
  );

  test('requires complete WebDAV credentials before initialization', () async {
    const config = WebDavConfig(url: 'https://dav.example.com/dav');
    var invoked = false;
    await expectLater(
      WebDavSetupService.initialize(
        config,
        check:
            ({
              required url,
              required username,
              required password,
              required path,
            }) async {
              invoked = true;
            },
        ensureDir:
            ({
              required url,
              required username,
              required password,
              required path,
            }) async {},
      ),
      throwsA(isA<StateError>()),
    );
    expect(invoked, isFalse);
  });
}
