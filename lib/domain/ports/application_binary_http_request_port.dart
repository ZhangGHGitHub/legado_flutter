import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'application_http_request_port.dart';

part 'application_binary_http_request_port.freezed.dart';

@freezed
class ApplicationBinaryHttpResponse with _$ApplicationBinaryHttpResponse {
  const factory ApplicationBinaryHttpResponse({
    required int statusCode,
    required String contentType,
    required Uint8List body,
  }) = _ApplicationBinaryHttpResponse;
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
