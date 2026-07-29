import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/rules/dict_rule.dart';
import 'package:legado_flutter/infrastructure/engine/frb_dict_rule_query_port.dart';

void main() {
  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);
  });

  test('FRB 字典端口执行 data URL 和 JS showRule', () async {
    const port = FrbDictRuleQueryPort();
    final result = await port.query(
      const DictRule(
        name: 'fixture',
        urlRule: 'data:text/plain;base64,5rWL6K+V',
        showRule: "@js:result + '完成'",
      ),
      'unused',
    );

    expect(result, '测试完成');
  });

  test('FRB 字典端口保留 Rust SSRF 拒绝', () async {
    const port = FrbDictRuleQueryPort();

    expect(
      port.query(
        const DictRule(name: 'private', urlRule: 'http://127.0.0.1/private'),
        'word',
      ),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('SSRF'),
          '包含 SSRF 拒绝原因',
        ),
      ),
    );
  });
}
