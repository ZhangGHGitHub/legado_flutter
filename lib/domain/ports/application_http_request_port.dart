import 'package:freezed_annotation/freezed_annotation.dart';

part 'application_http_request_port.freezed.dart';

enum ApplicationHttpPolicy { publicOnly, localNetwork }

@freezed
class ApplicationHttpResponse with _$ApplicationHttpResponse {
  const factory ApplicationHttpResponse({
    required int statusCode,
    required String body,
  }) = _ApplicationHttpResponse;
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
