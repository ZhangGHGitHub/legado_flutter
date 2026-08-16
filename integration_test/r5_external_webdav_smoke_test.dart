import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/infrastructure/webdav/frb_webdav_repository.dart';
import 'package:legado_flutter/services/backup_service.dart';
import 'package:legado_flutter/services/network_prefs.dart';

const _url = String.fromEnvironment('R5_EXTERNAL_WEBDAV_URL');
const _username = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_USER',
  defaultValue: '',
);
const _password = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_PASSWORD',
  defaultValue: '',
);
const _badPassword = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_BAD_PASSWORD',
  defaultValue: '',
);
const _proxyType = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_PROXY_TYPE',
  defaultValue: '',
);
const _proxyHost = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_PROXY_HOST',
  defaultValue: '',
);
const _proxyPort = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_PROXY_PORT',
  defaultValue: '',
);
const _proxyUser = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_PROXY_USER',
  defaultValue: '',
);
const _proxyPassword = String.fromEnvironment(
  'R5_EXTERNAL_WEBDAV_PROXY_PASSWORD',
  defaultValue: '',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R5-C external WebDAV regression', (tester) async {
    if (_url.trim().isEmpty) {
      markTestSkipped(
        'Set R5_EXTERNAL_WEBDAV_URL/USER/PASSWORD to run the external service gate.',
      );
      return;
    }
    expect(_username, isNotEmpty);
    expect(_password, isNotEmpty);

    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);
    await _applyProxyConfig();

    const WebDavRepository repository = FrbWebDavRepository();
    final root =
        '/r5-external-${DateTime.now().millisecondsSinceEpoch.toString()}';
    final filePath = '$root/etag.json';
    final zipPath = '$root/backup-r5-external.zip';
    final renamedPath = '$root/etag-renamed.json';

    await repository.check(
      url: _url,
      username: _username,
      password: _password,
      path: root,
    );
    await repository.ensureDir(
      url: _url,
      username: _username,
      password: _password,
      path: root,
    );

    if (_badPassword.isNotEmpty) {
      Object? error;
      try {
        await repository.check(
          url: _url,
          username: _username,
          password: _badPassword,
          path: root,
        );
      } catch (value) {
        error = value;
      }
      expect(error, isNotNull);
      expect(error.toString(), anyOf(contains('401'), contains('403')));
    }

    await repository.upload(
      url: _url,
      username: _username,
      password: _password,
      remotePath: filePath,
      data: utf8.encode('v1'),
    );
    final etag = await _readEtag(repository, root, 'etag.json');
    expect(etag, isNotEmpty);

    await repository.uploadIfMatch(
      url: _url,
      username: _username,
      password: _password,
      remotePath: filePath,
      data: utf8.encode('v2'),
      etag: etag,
    );

    Object? staleError;
    try {
      await repository.uploadIfMatch(
        url: _url,
        username: _username,
        password: _password,
        remotePath: filePath,
        data: utf8.encode('stale'),
        etag: etag,
      );
    } catch (error) {
      staleError = error;
    }
    expect(staleError, isNotNull);
    expect(staleError.toString(), contains('412'));

    await repository.move(
      url: _url,
      username: _username,
      password: _password,
      remotePath: filePath,
      destinationPath: renamedPath,
    );
    expect(
      utf8.decode(
        await repository.download(
          url: _url,
          username: _username,
          password: _password,
          remotePath: renamedPath,
        ),
      ),
      'v2',
    );

    final backupJson = jsonEncode({
      'version': 1,
      'database': <String, dynamic>{},
    });
    final zipBytes = BackupService.archiveJson(backupJson);
    await repository.upload(
      url: _url,
      username: _username,
      password: _password,
      remotePath: zipPath,
      data: zipBytes,
    );
    final downloadedZip = await repository.download(
      url: _url,
      username: _username,
      password: _password,
      remotePath: zipPath,
    );
    expect(BackupService.extractJson(downloadedZip), backupJson);
  });
}

Future<String> _readEtag(
  WebDavRepository repository,
  String root,
  String name,
) async {
  final entries = await repository.list(
    url: _url,
    username: _username,
    password: _password,
    path: root,
  );
  final entry = entries.firstWhere((item) => item.name == name);
  return entry.etag ?? '';
}

Future<void> _applyProxyConfig() async {
  if (_proxyType.trim().isEmpty || _proxyHost.trim().isEmpty) return;
  final port = int.tryParse(_proxyPort) ?? 0;
  expect(port, greaterThan(0));
  await NetworkPrefs.applyToEngine(
    NetworkPrefsConfig(
      proxyEnabled: true,
      proxyType: _proxyType,
      proxyHost: _proxyHost,
      proxyPort: port,
      proxyUsername: _proxyUser,
      proxyPassword: _proxyPassword,
    ),
  );
}
