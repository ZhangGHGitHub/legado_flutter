import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:legado_flutter/src/rust/api/error.dart';
import 'package:legado_flutter/src/rust/frb_generated.dart';

void main() {
  late _FakeEngineApi api;

  setUpAll(() {
    api = _FakeEngineApi();
    LegadoEngine.initMock(api: api);
  });

  tearDown(() {
    api.sourceUrl = null;
    api.header = null;
    api.error = null;
  });

  test('seedLoginHeader forwards source URL and header', () {
    rust_api.seedLoginHeader(
      sourceUrl: 'https://example.com/source',
      header: '{"Cookie":"sid=1"}',
    );

    expect(api.sourceUrl, 'https://example.com/source');
    expect(api.header, '{"Cookie":"sid=1"}');
  });

  test('seedLoginHeader preserves structured AppError failures', () {
    api.error = const AppError.unknown('登录头预热失败');

    expect(
      () => rust_api.seedLoginHeader(
        sourceUrl: 'https://example.com/source',
        header: '{"Cookie":"sid=1"}',
      ),
      throwsA(
        isA<AppError_Unknown>().having(
          (error) => error.field0,
          'original message',
          '登录头预热失败',
        ),
      ),
    );
  });
}

class _FakeEngineApi implements LegadoEngineApi {
  String? sourceUrl;
  String? header;
  AppError? error;

  @override
  void crateApiSeedLoginHeader({
    required String sourceUrl,
    required String header,
  }) {
    if (error case final error?) {
      throw error;
    }
    this.sourceUrl = sourceUrl;
    this.header = header;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('未预期的 Rust API 调用: ${invocation.memberName}');
  }
}
