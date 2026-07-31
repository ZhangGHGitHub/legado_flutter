final class OtherNetworkConfig {
  const OtherNetworkConfig({
    this.proxyEnabled = false,
    this.proxyType = 'http',
    this.proxyHost = '',
    this.proxyPort = 7890,
    this.proxyUsername = '',
    this.proxyPassword = '',
    this.dnsServers = '',
  });

  final bool proxyEnabled;
  final String proxyType;
  final String proxyHost;
  final int proxyPort;
  final String proxyUsername;
  final String proxyPassword;
  final String dnsServers;
}

abstract interface class OtherSettingsPort {
  bool get engineAvailable;

  Future<OtherNetworkConfig> loadNetwork();

  Future<void> saveNetwork(OtherNetworkConfig config);

  Future<void> applyNetwork(OtherNetworkConfig config);

  Future<String?> loadDataDir();

  Future<void> saveDataDir(String? path);

  Future<void> clearHttpTtsCache();
}
