import '../web_api_status.dart';

/// Local Web API lifecycle operations used by the application layer.
abstract interface class WebApiPort {
  bool get isAvailable;

  WebApiStatus? currentStatus();

  Future<WebApiStatus?> start({required int port, required String token});

  Future<void> stop();
}
