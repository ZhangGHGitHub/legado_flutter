import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/source_verification_browser_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_source_verification_browser_host.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;

class _BrowserPort implements SourceVerificationBrowserPort {
  SourceVerificationBrowserRequest? request;

  @override
  Future<SourceVerificationBrowserResult> openAndWait(
    SourceVerificationBrowserRequest request,
  ) async {
    this.request = request;
    return const SourceVerificationBrowserResult(
      finalUrl: 'https://example.com/done',
      body: '<html>done</html>',
    );
  }
}

void main() {
  test('maps FRB callback DTOs through the domain browser port', () async {
    final browserPort = _BrowserPort();
    late SourceBrowserHostCallback callback;
    final running = Completer<void>();
    final host = FrbSourceVerificationBrowserHost(
      browserPort: browserPort,
      server: (registered) {
        callback = registered;
        return running.future;
      },
    );

    host.start();
    await Future<void>.delayed(Duration.zero);
    final response = await callback(
      const rust_api.SourceBrowserRequestDto(
        sourceKey: 'https://source.example',
        url: 'https://source.example/verify',
        title: '验证',
        html: '<html>seed</html>',
        headers: {'X-Test': '1'},
        refetchAfterSuccess: false,
      ),
    );

    expect(browserPort.request?.sourceKey, 'https://source.example');
    expect(browserPort.request?.headers, {'X-Test': '1'});
    expect(browserPort.request?.html, '<html>seed</html>');
    expect(browserPort.request?.refetchAfterSuccess, isFalse);
    expect(response.finalUrl, 'https://example.com/done');
    expect(response.body, '<html>done</html>');
    running.complete();
  });
}
