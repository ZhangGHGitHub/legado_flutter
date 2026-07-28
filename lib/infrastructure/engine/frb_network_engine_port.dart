import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/network_engine_port.dart';
import '../../src/rust/api/network.dart' as network_api;

/// Rust/FRB 网络配置适配器。
class FrbNetworkEnginePort implements NetworkEnginePort {
  const FrbNetworkEnginePort();

  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

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
    if (!isAvailable) return;
    network_api.setNetworkConfig(
      proxyEnabled: proxyEnabled,
      proxyType: proxyType,
      proxyHost: proxyHost,
      proxyPort: proxyPort,
      proxyUsername: proxyUsername,
      proxyPassword: proxyPassword,
      dnsServers: dnsServers,
    );
  }

  @override
  void clearEngineCache() {
    if (!isAvailable) return;
    network_api.clearEngineCache();
  }
}
