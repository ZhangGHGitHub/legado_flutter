/// 网络偏好应用到书源引擎所需的最小端口。
///
/// 领域/应用服务只依赖这组参数，不直接依赖 FRB 生成 API。
abstract interface class NetworkEnginePort {
  bool get isAvailable;

  void setNetworkConfig({
    required bool proxyEnabled,
    required String proxyType,
    required String proxyHost,
    required int proxyPort,
    required String proxyUsername,
    required String proxyPassword,
    required String dnsServers,
  });

  void clearEngineCache();
}
