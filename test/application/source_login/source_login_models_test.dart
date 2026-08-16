import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_login/login_row_ui.dart';
import 'package:legado_flutter/application/source_login/source_login_page_port.dart';

void main() {
  group('Source login Freezed models', () {
    test('LoginRowUi preserves form fields, defaults, and derived label', () {
      const row = LoginRowUi(
        name: 'account',
        type: LoginRowType.text,
        viewName: '账号',
      );

      expect(row.defaultValue, isNull);
      expect(row.chars, isEmpty);
      expect(row.label, '账号');
      expect(row.copyWith(viewName: '').label, 'account');
      expect(row, equals(row.copyWith()));
      expect(() => row.chars.add('x'), throwsUnsupportedError);
    });

    test('SourceLoginCommand preserves script fields and value semantics', () {
      const command = SourceLoginCommand(
        operation: 'open',
        text: '登录',
        url: 'https://example.com/login',
        html: '<form>',
        data: {'method': 'post'},
      );

      expect(command, equals(command.copyWith()));
      expect(command.copyWith(text: '提交').text, '提交');
      expect(() => command.data!['method'] = 'get', throwsUnsupportedError);
    });

    test(
      'SourceLoginScriptResult preserves default session and command list',
      () {
        const command = SourceLoginCommand(operation: 'setCookie');
        const result = SourceLoginScriptResult(
          output: 'ok',
          commands: [command],
        );

        expect(result.loginInfo, isEmpty);
        expect(result, equals(result.copyWith()));
        expect(result.copyWith(loginInfo: {'cookie': 'a=b'}).loginInfo, {
          'cookie': 'a=b',
        });
        expect(() => result.commands.add(command), throwsUnsupportedError);
        expect(
          () => result.copyWith(loginInfo: {'cookie': 'a=b'}).loginInfo['x'] =
              'y',
          throwsUnsupportedError,
        );
      },
    );
  });
}
