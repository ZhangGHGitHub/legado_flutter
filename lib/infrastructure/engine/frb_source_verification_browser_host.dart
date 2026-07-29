import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/ports/source_verification_browser_port.dart';
import '../../src/rust/api.dart' as rust_api;

typedef SourceBrowserHostCallback =
    FutureOr<rust_api.SourceBrowserResponseDto> Function(
      rust_api.SourceBrowserRequestDto request,
    );
typedef SourceBrowserHostServer =
    Future<void> Function(SourceBrowserHostCallback callback);

class FrbSourceVerificationBrowserHost {
  FrbSourceVerificationBrowserHost({
    required SourceVerificationBrowserPort browserPort,
    SourceBrowserHostServer? server,
  }) : _browserPort = browserPort,
       _server = server ?? _serve;

  final SourceVerificationBrowserPort _browserPort;
  final SourceBrowserHostServer _server;

  void start() {
    unawaited(
      _server(_handle).catchError((Object error, StackTrace stackTrace) {
        debugPrint('[SourceBrowserHost] 宿主循环停止: $error');
      }),
    );
  }

  Future<rust_api.SourceBrowserResponseDto> _handle(
    rust_api.SourceBrowserRequestDto request,
  ) async {
    final result = await _browserPort.openAndWait(
      SourceVerificationBrowserRequest(
        sourceKey: request.sourceKey,
        url: request.url,
        title: request.title,
        html: request.html,
        headers: Map.unmodifiable(request.headers),
        refetchAfterSuccess: request.refetchAfterSuccess,
      ),
    );
    return rust_api.SourceBrowserResponseDto(
      finalUrl: result.finalUrl,
      body: result.body,
    );
  }

  static Future<void> _serve(SourceBrowserHostCallback callback) {
    return rust_api.serveSourceBrowserHost(host: callback);
  }
}
