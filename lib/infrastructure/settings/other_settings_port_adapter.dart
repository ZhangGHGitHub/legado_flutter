import '../../application/settings/other_settings_port.dart';
import '../../services/app_paths.dart';
import '../../services/engine_status_service.dart';
import '../../services/network_prefs.dart';
import '../../services/tts_service.dart';

final class OtherSettingsPortAdapter implements OtherSettingsPort {
  const OtherSettingsPortAdapter();

  @override
  bool get engineAvailable => EngineStatusService.isAvailable;

  @override
  Future<OtherNetworkConfig> loadNetwork() async {
    final value = await NetworkPrefs.load();
    return OtherNetworkConfig(
      proxyEnabled: value.proxyEnabled,
      proxyType: value.proxyType,
      proxyHost: value.proxyHost,
      proxyPort: value.proxyPort,
      proxyUsername: value.proxyUsername,
      proxyPassword: value.proxyPassword,
      dnsServers: value.dnsServers,
    );
  }

  @override
  Future<void> saveNetwork(OtherNetworkConfig config) => NetworkPrefs.save(
    NetworkPrefsConfig(
      proxyEnabled: config.proxyEnabled,
      proxyType: config.proxyType,
      proxyHost: config.proxyHost,
      proxyPort: config.proxyPort,
      proxyUsername: config.proxyUsername,
      proxyPassword: config.proxyPassword,
      dnsServers: config.dnsServers,
    ),
  );

  @override
  Future<void> applyNetwork(OtherNetworkConfig config) =>
      NetworkPrefs.applyToEngine(
        NetworkPrefsConfig(
          proxyEnabled: config.proxyEnabled,
          proxyType: config.proxyType,
          proxyHost: config.proxyHost,
          proxyPort: config.proxyPort,
          proxyUsername: config.proxyUsername,
          proxyPassword: config.proxyPassword,
          dnsServers: config.dnsServers,
        ),
      );

  @override
  Future<String?> loadDataDir() => AppDataPrefs.loadDataDir();

  @override
  Future<void> saveDataDir(String? path) => AppDataPrefs.saveDataDir(path);

  @override
  Future<void> clearHttpTtsCache() => TtsService.instance.clearHttpTtsCache();
}
