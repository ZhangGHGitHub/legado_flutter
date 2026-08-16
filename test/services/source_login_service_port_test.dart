import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/js_eval_port.dart';
import 'package:legado_flutter/services/source_login_service.dart';

void main() {
  tearDown(SourceLoginService.resetJsPort);

  test('reset clears the configured JS port', () {
    SourceLoginService.configureJsPort(_FakeJsEvalPort());
    SourceLoginService.resetJsPort();

    expect(() => SourceLoginService.eval('login()'), throwsStateError);
  });

  test('SourceLoginService forwards JS execution through the port', () {
    final port = _FakeJsEvalPort(result: '[{"name":"账号"}]');
    SourceLoginService.configureJsPort(port);

    final result = SourceLoginService.eval(
      'loginUi()',
      jsLib: 'var helper = true;',
      baseUrl: 'https://example.test/login',
    );

    expect(result, '[{"name":"账号"}]');
    expect(port.script, 'loginUi()');
    expect(port.jsLib, 'var helper = true;');
    expect(port.baseUrl, 'https://example.test/login');
  });

  test('SourceLoginService keeps unavailable JS errors from the port', () {
    SourceLoginService.configureJsPort(_FakeJsEvalPort(isAvailable: false));

    expect(
      () => SourceLoginService.eval('login()'),
      throwsA(isA<StateError>()),
    );
  });
}

class _FakeJsEvalPort implements JsEvalPort {
  _FakeJsEvalPort({this.result = '', this.isAvailable = true});

  final String result;

  @override
  final bool isAvailable;

  String? script;
  String? jsLib;
  String? baseUrl;

  @override
  String eval({
    required String script,
    required String jsLib,
    required String baseUrl,
  }) {
    if (!isAvailable) throw StateError('unavailable');
    this.script = script;
    this.jsLib = jsLib;
    this.baseUrl = baseUrl;
    return result;
  }
}
