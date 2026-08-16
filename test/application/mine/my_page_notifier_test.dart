import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/mine/my_page_notifier.dart';
import 'package:legado_flutter/application/mine/my_page_port.dart';
import 'package:legado_flutter/application/mine/my_page_state.dart';

void main() {
  test('Notifier loads and publishes the active Web service state', () async {
    final port = _FakeMyPagePort(
      loadStatus: const MyPageWebServiceStatus(
        enabled: true,
        running: true,
        baseUrl: 'http://127.0.0.1:1122',
      ),
    );
    final container = ProviderContainer(
      overrides: [myPagePortProvider.overrideWithValue(port)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(myPageNotifierProvider.notifier);
    await notifier.loadWebService();

    final state = container.read(myPageNotifierProvider);
    expect(state.webServiceLoadState, MyPageWebServiceLoadState.ready);
    expect(state.webServiceOn, isTrue);
    expect(state.webServiceUrl, 'http://127.0.0.1:1122');
  });

  test('Notifier exposes backup busy and success states', () async {
    final backup = Completer<String>();
    final port = _FakeMyPagePort(backup: backup);
    final container = ProviderContainer(
      overrides: [myPagePortProvider.overrideWithValue(port)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(myPageNotifierProvider.notifier);

    final pending = notifier.backupLocally();
    expect(
      container.read(myPageNotifierProvider).backupState,
      MyPageBackupState.running,
    );

    backup.complete('backup.zip');
    expect(await pending, 'backup.zip');
    final state = container.read(myPageNotifierProvider);
    expect(state.backupState, MyPageBackupState.success);
    expect(state.backupFileName, 'backup.zip');
    expect(state.localBackupBusy, isFalse);
  });

  test('Notifier records Web service and backup failures', () async {
    final port = _FakeMyPagePort(
      loadError: StateError('load failed'),
      backupError: StateError('backup failed'),
    );
    final container = ProviderContainer(
      overrides: [myPagePortProvider.overrideWithValue(port)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(myPageNotifierProvider.notifier);

    await notifier.loadWebService();
    expect(
      container.read(myPageNotifierProvider).webServiceLoadState,
      MyPageWebServiceLoadState.failure,
    );
    expect(
      container.read(myPageNotifierProvider).webServiceError,
      contains('load failed'),
    );

    await expectLater(notifier.backupLocally(), throwsStateError);
    expect(
      container.read(myPageNotifierProvider).backupState,
      MyPageBackupState.failure,
    );
    expect(
      container.read(myPageNotifierProvider).backupError,
      contains('backup failed'),
    );
  });
}

final class _FakeMyPagePort implements MyPagePort {
  _FakeMyPagePort({
    this.loadStatus = const MyPageWebServiceStatus(
      enabled: false,
      running: false,
    ),
    this.loadError,
    this.backup,
    this.backupError,
  });

  final MyPageWebServiceStatus loadStatus;
  final Object? loadError;
  final Completer<String>? backup;
  final Object? backupError;

  @override
  bool get isEngineAvailable => true;

  @override
  bool get isDatabaseReady => true;

  @override
  String get engineVersion => 'test';

  @override
  Future<MyPageWebServiceStatus> loadWebService() async {
    if (loadError != null) throw loadError!;
    return loadStatus;
  }

  @override
  Future<MyPageWebServiceStatus> toggleWebService() async => loadStatus;

  @override
  Future<String> backupLocally() async {
    if (backupError != null) throw backupError!;
    return backup?.future ?? 'backup.zip';
  }
}
