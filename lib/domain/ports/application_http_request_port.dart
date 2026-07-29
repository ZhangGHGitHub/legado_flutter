enum ApplicationHttpPolicy { publicOnly, localNetwork }

class ApplicationHttpResponse {
  const ApplicationHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

abstract interface class ApplicationHttpRequestPort {
  Future<ApplicationHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    String body = '',
    int timeoutSeconds = 30,
    required ApplicationHttpPolicy policy,
  });
}
