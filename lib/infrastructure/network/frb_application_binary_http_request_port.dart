import 'dart:typed_data';

import '../../domain/ports/application_binary_http_request_port.dart';
import '../../domain/ports/application_http_request_port.dart';
import '../../src/rust/api/network.dart' as network_api;

class FrbApplicationBinaryHttpRequestPort
    implements ApplicationBinaryHttpRequestPort {
  const FrbApplicationBinaryHttpRequestPort();

  @override
  Future<ApplicationBinaryHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    Uint8List? body,
    int timeoutSeconds = 30,
    int maxResponseBytes = 0,
    required ApplicationHttpPolicy policy,
  }) async {
    final response = await network_api.sendApplicationBinaryHttpRequest(
      url: url,
      method: method,
      headers: headers,
      body: body,
      timeoutSeconds: timeoutSeconds,
      allowPrivateNetwork: policy == ApplicationHttpPolicy.localNetwork,
      maxResponseBytes: maxResponseBytes,
    );
    return ApplicationBinaryHttpResponse(
      statusCode: response.statusCode,
      contentType: response.contentType,
      body: response.body,
    );
  }
}
