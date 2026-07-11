import 'package:shared_preferences/shared_preferences.dart';

import '../bridge/legado_engine_bridge.dart';
import '../src/rust/api/network.dart' as network_api;

/// 网络代理 / DNS 偏好（Phase 4.3）
class NetworkPrefsConfig {
  final bool proxyEnabled;
  final String proxyType;
  final String proxyHost;
  final int proxyPort;
  final String proxyUsername;
  final String proxyPassword;
  final String dnsServers;

  const NetworkPrefsConfig({
    this.proxyEnabled = false,
    this.proxyType = 'http',
    this.proxyHost = '',
    this.proxyPort = 7890,
    this.proxyUsername = '',
    this.proxyPassword = '',
    this.dnsServers = '',
  });

  NetworkPrefsConfig copyWith({
    bool? proxyEnabled,
    String? proxyType,
    String? proxyHost,
    int? proxyPort,
    String? proxyUsername,
    String? proxyPassword,
    String? dnsServers,
  }) {
    return NetworkPrefsConfig(
      proxyEnabled: proxyEnabled ?? this.proxyEnabled,
      proxyType: proxyType ?? this.proxyType,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
      proxyUsername: proxyUsername ?? this.proxyUsername,
      proxyPassword: proxyPassword ?? this.proxyPassword,
      dnsServers: dnsServers ?? this.dnsServers,
    );
  }
}

abstract final class NetworkPrefs {
  static const enabledKey = 'net_proxy_enabled';
  static const typeKey = 'net_proxy_type';
  static const hostKey = 'net_proxy_host';
  static const portKey = 'net_proxy_port';
  static const userKey = 'net_proxy_user';
  static const passKey = 'net_proxy_pass';
  static const dnsKey = 'net_dns_servers';

  static Future<NetworkPrefsConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NetworkPrefsConfig(
      proxyEnabled: prefs.getBool(enabledKey) ?? false,
      proxyType: prefs.getString(typeKey) ?? 'http',
      proxyHost: prefs.getString(hostKey) ?? '',
      proxyPort: prefs.getInt(portKey) ?? 7890,
      proxyUsername: prefs.getString(userKey) ?? '',
      proxyPassword: prefs.getString(passKey) ?? '',
      dnsServers: prefs.getString(dnsKey) ?? '',
    );
  }

  static Future<void> save(NetworkPrefsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, config.proxyEnabled);
    await prefs.setString(typeKey, config.proxyType);
    await prefs.setString(hostKey, config.proxyHost);
    await prefs.setInt(portKey, config.proxyPort);
    await prefs.setString(userKey, config.proxyUsername);
    await prefs.setString(passKey, config.proxyPassword);
    await prefs.setString(dnsKey, config.dnsServers);
  }

  static Future<void> applyToEngine(NetworkPrefsConfig config) async {
    if (!LegadoEngineBridge.isAvailable) return;
    network_api.setNetworkConfig(
      proxyEnabled: config.proxyEnabled,
      proxyType: config.proxyType,
      proxyHost: config.proxyHost,
      proxyPort: config.proxyPort,
      proxyUsername: config.proxyUsername,
      proxyPassword: config.proxyPassword,
      dnsServers: config.dnsServers,
    );
  }

  static Future<void> restoreToEngine() async {
    await applyToEngine(await load());
  }
}
