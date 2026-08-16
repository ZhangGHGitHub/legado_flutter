import '../../domain/ports/application_http_request_port.dart';
import '../../src/rust/api/network.dart' as network_api;

class FrbApplicationHttpRequestPort implements ApplicationHttpRequestPort {
  const FrbApplicationHttpRequestPort();

  @override
  Future<ApplicationHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    String body = '',
    int timeoutSeconds = 30,
    required ApplicationHttpPolicy policy,
  }) async {
    final response = await network_api.sendApplicationHttpRequest(
      url: url,
      method: method,
      headers: headers,
      body: body.isEmpty ? null : body,
      timeoutSeconds: timeoutSeconds,
      allowPrivateNetwork: policy == ApplicationHttpPolicy.localNetwork,
    );
    return ApplicationHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
