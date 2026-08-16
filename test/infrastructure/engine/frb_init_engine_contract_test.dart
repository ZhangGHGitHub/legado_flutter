import 'dart:io';

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
    api.error = null;
    api.callCount = 0;
  });

  test('initEngine keeps the successful initialization contract', () {
    rust_api.initEngine();

    expect(api.callCount, 1);
  });

  test('initEngine preserves structured AppError failures', () {
    api.error = const AppError.unknown('引擎初始化失败: 原始错误');

    expect(
      rust_api.initEngine,
      throwsA(
        isA<AppError_Unknown>().having(
          (error) => error.field0,
          'original message',
          '引擎初始化失败: 原始错误',
        ),
      ),
    );
  });

  test('generated initEngine binding decodes AppError instead of String', () {
    final generated = File('lib/src/rust/frb_generated.dart').readAsStringSync();
    final initEngineStart = generated.indexOf('void crateApiInitEngine() {');
    final initEngineMeta = generated.indexOf(
      'constMeta: kCrateApiInitEngineConstMeta',
      initEngineStart,
    );

    expect(initEngineStart, greaterThanOrEqualTo(0));
    expect(initEngineMeta, greaterThan(initEngineStart));
    expect(
      generated.substring(initEngineStart, initEngineMeta),
      contains('decodeErrorData: sse_decode_app_error'),
    );
  });
}

class _FakeEngineApi implements LegadoEngineApi {
  AppError? error;
  int callCount = 0;

  @override
  void crateApiInitEngine() {
    if (error case final error?) {
      throw error;
    }
    callCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('未预期的 Rust API 调用: ${invocation.memberName}');
  }
}
