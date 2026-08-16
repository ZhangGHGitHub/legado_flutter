/// “我的”页面需要的本地 Web 服务状态。
final class MyPageWebServiceStatus {
  const MyPageWebServiceStatus({
    required this.enabled,
    required this.running,
    this.baseUrl = '',
  });

  final bool enabled;
  final bool running;
  final String baseUrl;

  bool get isActive => enabled && running;
}

/// “我的”页面的基础设施边界。
///
/// 页面只通过该端口读取运行状态并执行操作，不直接依赖服务或偏好存储。
abstract interface class MyPagePort {
  bool get isEngineAvailable;

  bool get isDatabaseReady;

  String get engineVersion;

  Future<MyPageWebServiceStatus> loadWebService();

  Future<MyPageWebServiceStatus> toggleWebService();

  Future<String> backupLocally();
}
