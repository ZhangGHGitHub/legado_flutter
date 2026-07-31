import '../../domain/rules/dict_rule.dart';

/// Application boundary for loading and executing dictionary rules.
abstract interface class DictLookupPort {
  Future<List<DictRule>> loadRules();

  Future<String> queryRule(DictRule rule, String word);
}

/// Degrades to an empty dictionary until the composition root supplies a port.
final class UnavailableDictLookupPort implements DictLookupPort {
  const UnavailableDictLookupPort();

  @override
  Future<List<DictRule>> loadRules() => Future.value(const []);

  @override
  Future<String> queryRule(DictRule rule, String word) =>
      Future<String>.error(StateError('词典查询端口不可用'));
}
