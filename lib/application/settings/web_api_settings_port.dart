import '../../domain/web_api_status.dart';

/// 配置页 Web API 服务的运行控制边界。
///
/// 页面只通过该端口读取状态、启停服务和构造 API 地址。
abstract interface class WebApiSettingsPort {
  bool get isAvailable;

  WebApiStatus? currentStatus();

  Future<WebApiStatus?> setEnabled(bool enabled);

  Future<WebApiStatus?> start({int? port, String? token});

  String apiUrl(WebApiStatus status, String path);
}
