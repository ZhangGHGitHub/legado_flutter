/// Pure Dart status of the local Web API server.
class WebApiStatus {
  const WebApiStatus({
    required this.running,
    required this.port,
    required this.token,
    required this.baseUrl,
  });

  final bool running;
  final int port;
  final String token;
  final String baseUrl;
}
