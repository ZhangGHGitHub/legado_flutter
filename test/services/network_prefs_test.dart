import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/network_engine_port.dart';
import 'package:legado_flutter/services/network_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(NetworkPrefs.resetEnginePort);
  SharedPreferences.setMockInitialValues({});

  test('NetworkPrefs defaults and roundtrip', () async {
    final initial = await NetworkPrefs.load();
    expect(initial.proxyEnabled, isFalse);
    expect(initial.proxyType, 'http');
    expect(initial.proxyPort, 7890);

    await NetworkPrefs.save(
      const NetworkPrefsConfig(
        proxyEnabled: true,
        proxyType: 'socks5',
        proxyHost: '127.0.0.1',
        proxyPort: 1080,
        proxyUsername: 'user',
        proxyPassword: 'pass',
        dnsServers: '8.8.8.8,1.1.1.1',
      ),
    );

    final loaded = await NetworkPrefs.load();
    expect(loaded.proxyEnabled, isTrue);
    expect(loaded.proxyType, 'socks5');
    expect(loaded.proxyHost, '127.0.0.1');
    expect(loaded.proxyPort, 1080);
    expect(loaded.proxyUsername, 'user');
    expect(loaded.proxyPassword, 'pass');
    expect(loaded.dnsServers, '8.8.8.8,1.1.1.1');
  });

  test('NetworkPrefsConfig copyWith', () {
    const base = NetworkPrefsConfig(proxyHost: 'a');
    final copy = base.copyWith(proxyHost: 'b', proxyEnabled: true);
    expect(copy.proxyHost, 'b');
    expect(copy.proxyEnabled, isTrue);
    expect(copy.proxyType, base.proxyType);
  });

  test(
    'applyToEngine forwards the stored network config through the port',
    () async {
      final port = _FakeNetworkEnginePort();
      NetworkPrefs.configureEnginePort(port);

      await NetworkPrefs.applyToEngine(
        const NetworkPrefsConfig(
          proxyEnabled: true,
          proxyType: 'socks5',
          proxyHost: '127.0.0.1',
          proxyPort: 1080,
          proxyUsername: 'user',
          proxyPassword: 'pass',
          dnsServers: '1.1.1.1',
        ),
      );

      expect(port.lastConfig, {
        'proxyEnabled': true,
        'proxyType': 'socks5',
        'proxyHost': '127.0.0.1',
        'proxyPort': 1080,
        'proxyUsername': 'user',
        'proxyPassword': 'pass',
        'dnsServers': '1.1.1.1',
      });
    },
  );

  test('applyToEngine does not call an unavailable port', () async {
    final port = _FakeNetworkEnginePort(isAvailable: false);
    NetworkPrefs.configureEnginePort(port);

    await NetworkPrefs.applyToEngine(const NetworkPrefsConfig());

    expect(port.lastConfig, isNull);
  });

  test('reset clears the configured network engine port', () async {
    final port = _FakeNetworkEnginePort();
    NetworkPrefs.configureEnginePort(port);
    NetworkPrefs.resetEnginePort();

    await NetworkPrefs.applyToEngine(const NetworkPrefsConfig());

    expect(port.lastConfig, isNull);
  });
}

class _FakeNetworkEnginePort implements NetworkEnginePort {
  _FakeNetworkEnginePort({this.isAvailable = true});

  @override
  final bool isAvailable;

  Map<String, Object>? lastConfig;

  @override
  void setNetworkConfig({
    required bool proxyEnabled,
    required String proxyType,
    required String proxyHost,
    required int proxyPort,
    required String proxyUsername,
    required String proxyPassword,
    required String dnsServers,
  }) {
    lastConfig = {
      'proxyEnabled': proxyEnabled,
      'proxyType': proxyType,
      'proxyHost': proxyHost,
      'proxyPort': proxyPort,
      'proxyUsername': proxyUsername,
      'proxyPassword': proxyPassword,
      'dnsServers': dnsServers,
    };
  }

  @override
  void clearEngineCache() {}
}
