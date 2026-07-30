/// Web API 本地配置及其持久化端口。
final class WebApiConfig {
  final bool enabled;
  final int port;
  final String token;

  const WebApiConfig({
    this.enabled = false,
    this.port = 1122,
    this.token = '',
  });

  WebApiConfig copyWith({bool? enabled, int? port, String? token}) {
    return WebApiConfig(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      token: token ?? this.token,
    );
  }
}

abstract interface class WebApiPrefsPort {
  static const defaultPort = 1122;

  Future<WebApiConfig> load();

  Future<void> save(WebApiConfig config);
}
