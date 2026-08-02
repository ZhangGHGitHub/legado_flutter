import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_verification_browser_port.freezed.dart';

@freezed
class SourceVerificationBrowserRequest with _$SourceVerificationBrowserRequest {
  const factory SourceVerificationBrowserRequest({
    required String sourceKey,
    required String url,
    required String title,
    required String? html,
    required Map<String, String> headers,
    required bool refetchAfterSuccess,
  }) = _SourceVerificationBrowserRequest;
}

@freezed
class SourceVerificationBrowserResult with _$SourceVerificationBrowserResult {
  const factory SourceVerificationBrowserResult({
    required String finalUrl,
    required String body,
  }) = _SourceVerificationBrowserResult;
}

class SourceVerificationCancelled implements Exception {
  const SourceVerificationCancelled();

  @override
  String toString() => '用户取消了书源网页验证';
}

abstract interface class SourceVerificationBrowserPort {
  Future<SourceVerificationBrowserResult> openAndWait(
    SourceVerificationBrowserRequest request,
  );
}
