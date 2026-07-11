import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/network_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}
