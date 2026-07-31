import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:legado_flutter/src/rust/api/error.dart';
import 'package:legado_flutter/src/rust/frb_generated.dart';

void main() {
  setUpAll(() {
    LegadoEngine.initMock(api: _FakeEngineApi());
  });

  test('evalJs preserves a successful result through the generated API', () {
    expect(rust_api.evalJs(script: '1 + 1', jsLib: '', baseUrl: ''), '结果:2');
  });

  test('evalJs propagates the structured JavaScript error variant', () {
    const message = 'JS 执行失败: 原始 JS 错误';

    expect(
      () => rust_api.evalJs(script: 'throw', jsLib: '', baseUrl: ''),
      throwsA(
        isA<AppError_JsExecution>().having(
          (error) => error.field0,
          'original message',
          message,
        ),
      ),
    );
  });
}

class _FakeEngineApi implements LegadoEngineApi {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #crateApiEvalJs) {
      final script = invocation.namedArguments[#script] as String;
      if (script == 'throw') {
        throw AppError.jsExecution('JS 执行失败: 原始 JS 错误');
      }
      return '结果:2';
    }

    throw UnsupportedError('未预期的 Rust API 调用: ${invocation.memberName}');
  }
}
