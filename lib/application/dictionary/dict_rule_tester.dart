import '../../domain/ports/dict_rule_query_port.dart';
import '../../domain/rules/dict_rule.dart';
import '../../utils/ssrf_guard.dart';

class DictRuleTester {
  const DictRuleTester(this._queryPort);

  final DictRuleQueryPort _queryPort;

  Future<String> test(DictRule rule, String word) {
    final key = word.trim();
    if (key.isEmpty) {
      throw ArgumentError('请输入测试词');
    }
    final urlRule = rule.urlRule.trim();
    if (urlRule.isEmpty) {
      throw ArgumentError('URL 规则为空');
    }

    // JS/模板规则必须交给 Rust AnalyzeUrl 展开；纯 URL 可在跨端口前快速拒绝私网。
    if (urlRule.startsWith('http://') || urlRule.startsWith('https://')) {
      final options = urlRule.indexOf(',{');
      final requestUrl = options < 0 ? urlRule : urlRule.substring(0, options);
      SsrfGuard.assertPublicHttpUrl(requestUrl);
    }
    return _queryPort.query(rule, key);
  }
}
