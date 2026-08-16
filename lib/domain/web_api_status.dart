import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_api_status.freezed.dart';

/// Pure Dart status of the local Web API server.
@freezed
class WebApiStatus with _$WebApiStatus {
  const factory WebApiStatus({
    required bool running,
    required int port,
    required String token,
    required String baseUrl,
  }) = _WebApiStatus;
}
