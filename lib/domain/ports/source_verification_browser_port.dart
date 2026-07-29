class SourceVerificationBrowserRequest {
  const SourceVerificationBrowserRequest({
    required this.sourceKey,
    required this.url,
    required this.title,
    required this.html,
    required this.headers,
    required this.refetchAfterSuccess,
  });

  final String sourceKey;
  final String url;
  final String title;
  final String? html;
  final Map<String, String> headers;
  final bool refetchAfterSuccess;
}

class SourceVerificationBrowserResult {
  const SourceVerificationBrowserResult({
    required this.finalUrl,
    required this.body,
  });

  final String finalUrl;
  final String body;
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
