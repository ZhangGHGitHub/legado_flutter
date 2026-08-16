import '../../application/settings/web_api_settings_port.dart';
import '../../domain/web_api_status.dart';
import '../../services/web_api_service.dart';

typedef WebApiSettingsAvailabilityReader = bool Function();
typedef WebApiSettingsStatusReader = WebApiStatus? Function();
typedef WebApiSettingsToggle = Future<WebApiStatus?> Function(bool enabled);
typedef WebApiSettingsStarter =
    Future<WebApiStatus?> Function({int? port, String? token});
typedef WebApiSettingsUrlBuilder =
    String Function(WebApiStatus status, String path);

/// 将配置页 Web API 运行控制接入既有静态服务。
final class WebApiSettingsPortAdapter implements WebApiSettingsPort {
  WebApiSettingsPortAdapter({
    WebApiSettingsAvailabilityReader? isAvailable,
    WebApiSettingsStatusReader? currentStatus,
    WebApiSettingsToggle? setEnabled,
    WebApiSettingsStarter? start,
    WebApiSettingsUrlBuilder? apiUrl,
  }) : _isAvailable = isAvailable ?? (() => WebApiService.isAvailable),
       _currentStatus = currentStatus ?? WebApiService.currentStatus,
       _setEnabled = setEnabled ?? WebApiService.setEnabled,
       _start = start ?? WebApiService.start,
       _apiUrl = apiUrl ?? WebApiService.apiUrl;

  final WebApiSettingsAvailabilityReader _isAvailable;
  final WebApiSettingsStatusReader _currentStatus;
  final WebApiSettingsToggle _setEnabled;
  final WebApiSettingsStarter _start;
  final WebApiSettingsUrlBuilder _apiUrl;

  @override
  bool get isAvailable => _isAvailable();

  @override
  WebApiStatus? currentStatus() => _currentStatus();

  @override
  Future<WebApiStatus?> setEnabled(bool enabled) => _setEnabled(enabled);

  @override
  Future<WebApiStatus?> start({int? port, String? token}) =>
      _start(port: port, token: token);

  @override
  String apiUrl(WebApiStatus status, String path) => _apiUrl(status, path);
}
