import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/web_api/web_api_prefs_port.dart';
import 'package:legado_flutter/domain/web_api_status.dart';
import 'package:legado_flutter/infrastructure/mine/my_page_port_adapter.dart';

void main() {
  test('maps web service state and toggles persisted enabled state', () async {
    var enabled = false;
    var requestedEnabled = false;
    const runningStatus = WebApiStatus(
      running: true,
      port: 1122,
      token: 'token',
      baseUrl: 'http://127.0.0.1:1122',
    );
    final adapter = MyPagePortAdapter(
      loadWebApiConfig: () async => _config(enabled),
      toggleWebApi: (value) async {
        requestedEnabled = value;
        enabled = value;
        return runningStatus;
      },
      currentWebApiStatus: () => runningStatus,
      backupToLocalFile: () async => File(r'C:\backups\backup.zip'),
      isEngineAvailable: () => true,
      isDatabaseReady: () => true,
      engineVersion: () => '0.5.6',
    );

    final initial = await adapter.loadWebService();
    expect(initial.enabled, isFalse);
    expect(initial.isActive, isFalse);

    final toggled = await adapter.toggleWebService();
    expect(requestedEnabled, isTrue);
    expect(toggled.enabled, isTrue);
    expect(toggled.isActive, isTrue);
    expect(toggled.baseUrl, runningStatus.baseUrl);
  });

  test(
    'exposes readiness and returns only the local backup filename',
    () async {
      final adapter = MyPagePortAdapter(
        backupToLocalFile: () async => File(r'C:\backups\backup-2026.zip'),
        isEngineAvailable: () => true,
        isDatabaseReady: () => false,
        engineVersion: () => '0.5.6',
      );

      expect(adapter.isEngineAvailable, isTrue);
      expect(adapter.isDatabaseReady, isFalse);
      expect(adapter.engineVersion, '0.5.6');
      expect(await adapter.backupLocally(), 'backup-2026.zip');
    },
  );
}

Future<WebApiConfig> _config(bool enabled) async =>
    WebApiConfig(enabled: enabled);
