import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:legado_flutter/services/webdav_setup_service.dart';

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
