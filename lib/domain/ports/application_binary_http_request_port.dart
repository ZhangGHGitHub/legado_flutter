import 'dart:typed_data';

import 'application_http_request_port.dart';

class ApplicationBinaryHttpResponse {
  const ApplicationBinaryHttpResponse({
    required this.statusCode,
    required this.contentType,
    required this.body,
  });

  final int statusCode;
  final String contentType;
  final Uint8List body;
}

abstract interface class ApplicationBinaryHttpRequestPort {
  Future<ApplicationBinaryHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    Uint8List? body,
    int timeoutSeconds = 30,
    int maxResponseBytes = 0,
    required ApplicationHttpPolicy policy,
  });
}
