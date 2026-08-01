import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/source_verification_browser_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_source_verification_browser_host.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:legado_flutter/src/rust/api/error.dart';
import 'package:legado_flutter/src/rust/frb_generated.dart';

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

class _ThrowingBrowserPort implements SourceVerificationBrowserPort {
  _ThrowingBrowserPort(this.error);

  final Object error;

  @override
  Future<SourceVerificationBrowserResult> openAndWait(
    SourceVerificationBrowserRequest request,
  ) async {
    throw error;
  }
}

void main() {
  late _FakeEngineApi engineApi;

  setUpAll(() {
    engineApi = _FakeEngineApi();
    LegadoEngine.initMock(api: engineApi);
  });

  tearDown(() {
    engineApi.probeError = null;
    engineApi.serveError = null;
  });

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

  test('passes domain browser errors back through the callback', () async {
    late SourceBrowserHostCallback callback;
    final running = Completer<void>();
    final host = FrbSourceVerificationBrowserHost(
      browserPort: _ThrowingBrowserPort(UnsupportedError('当前平台不支持书源网页验证')),
      server: (registered) {
        callback = registered;
        return running.future;
      },
    );

    host.start();
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      callback(
        const rust_api.SourceBrowserRequestDto(
          sourceKey: 'https://source.example',
          url: 'https://source.example/verify',
          title: '验证',
          html: null,
          headers: {},
          refetchAfterSuccess: false,
        ),
      ),
      throwsA(isA<UnsupportedError>()),
    );
    running.complete();
  });

  test('probeSourceBrowserHost preserves structured cancellation', () async {
    engineApi.probeError = const AppError.cancelled('用户取消验证');

    await expectLater(
      rust_api.probeSourceBrowserHost(
        request: const rust_api.SourceBrowserRequestDto(
          sourceKey: 'https://source.example',
          url: 'https://source.example/verify',
          title: '验证',
          html: null,
          headers: {},
          refetchAfterSuccess: true,
        ),
      ),
      throwsA(
        isA<AppError_Cancelled>().having(
          (error) => error.field0,
          'original message',
          '用户取消验证',
        ),
      ),
    );
  });

  test('serveSourceBrowserHost preserves structured host failures', () async {
    engineApi.serveError = const AppError.unknown('浏览器宿主锁失败');

    await expectLater(
      rust_api.serveSourceBrowserHost(
        host: (_) => const rust_api.SourceBrowserResponseDto(
          finalUrl: 'https://source.example/done',
          body: '<html>done</html>',
        ),
      ),
      throwsA(
        isA<AppError_Unknown>().having(
          (error) => error.field0,
          'original message',
          '浏览器宿主锁失败',
        ),
      ),
    );
  });
}

class _FakeEngineApi implements LegadoEngineApi {
  AppError? probeError;
  AppError? serveError;

  @override
  Future<rust_api.SourceBrowserResponseDto> crateApiProbeSourceBrowserHost({
    required rust_api.SourceBrowserRequestDto request,
  }) async {
    if (probeError case final error?) {
      throw error;
    }
    return rust_api.SourceBrowserResponseDto(
      finalUrl: request.url,
      body: request.html ?? '',
    );
  }

  @override
  Future<void> crateApiServeSourceBrowserHost({
    required FutureOr<rust_api.SourceBrowserResponseDto> Function(
      rust_api.SourceBrowserRequestDto,
    )
    host,
  }) async {
    if (serveError case final error?) {
      throw error;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('未预期的 Rust API 调用: ${invocation.memberName}');
  }
}
