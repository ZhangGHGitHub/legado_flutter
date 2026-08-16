import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_login/login_row_ui.dart';
import 'package:legado_flutter/models/login_row_ui.dart' as legacy;

void main() {
  test('fromJson preserves aliases, fallbacks, defaults, and chars', () {
    final row = LoginRowUi.fromJson({
      'name': 'account',
      'type': 'spinner',
      'hint': '账号',
      'default': 42,
      'chars': ['a', 2, null],
    });

    expect(row.name, 'account');
    expect(row.type, LoginRowType.select);
    expect(row.label, '账号');
    expect(row.defaultValue, '42');
    expect(row.chars, ['a', '2']);
    expect(
      LoginRowUi.fromJson({'name': 'enabled', 'type': 'bool'}).type,
      LoginRowType.checkbox,
    );
  });

  test('parse keeps valid named rows and rejects invalid or JS input', () {
    final rows = LoginRowUi.parse('''
      [
        {"name":"username","type":"text"},
        {"name":"","type":"password"},
        "ignored"
      ]
    ''');

    expect(rows, hasLength(1));
    expect(rows.single.name, 'username');
    expect(LoginRowUi.parse('{"name":"not-a-list"}'), isEmpty);
    expect(LoginRowUi.parse('invalid json'), isEmpty);
    expect(LoginRowUi.parse('@js: loginUi()'), isEmpty);
    expect(LoginRowUi.parse('<js>loginUi()'), isEmpty);
    expect(LoginRowUi.parse('<JS>loginUi()'), isEmpty);
  });

  test('legacy model path remains a compatibility export', () {
    const row = legacy.LoginRowUi(
      name: 'password',
      type: legacy.LoginRowType.password,
    );

    expect(row, isA<LoginRowUi>());
    expect(legacy.LoginRowUi.isJsLoginUi('  @js: loginUi()'), isTrue);
  });
}
