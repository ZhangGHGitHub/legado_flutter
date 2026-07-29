import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/providers/replace_provider.dart';

class _FakeReplaceRuleRepository implements ReplaceRuleRepository {
  final List<ReplaceRule> rules = [];

  @override
  Future<List<ReplaceRule>> getAll() async => List.unmodifiable(rules);

  @override
  Future<void> insert(ReplaceRule rule) async {
    rules.removeWhere((item) => item.id == rule.id);
    rules.add(rule);
  }

  @override
  Future<void> insertAll(List<ReplaceRule> values) async {
    for (final rule in values) {
      await insert(rule);
    }
  }

  @override
  Future<void> update(ReplaceRule rule) => insert(rule);

  @override
  Future<void> toggle(String ruleId, bool enabled) async {
    final index = rules.indexWhere((rule) => rule.id == ruleId);
    if (index < 0) return;
    final rule = rules[index];
    rules[index] = ReplaceRule(
      id: rule.id,
      name: rule.name,
      pattern: rule.pattern,
      replacement: rule.replacement,
      isEnabled: enabled,
      isRegex: rule.isRegex,
    );
  }

  @override
  Future<void> delete(String ruleId) async {
    rules.removeWhere((rule) => rule.id == ruleId);
  }

  @override
  Future<void> clear() async => rules.clear();
}

void main() {
  test('ReplaceProvider persists CRUD through the repository port', () async {
    final repository = _FakeReplaceRuleRepository();
    final provider = ReplaceProvider(
      repository: repository,
      contentProcessor: ContentProcessorAdapter(),
    );

    await provider.loadRules();
    expect(provider.replaceRules, isNotEmpty);
    expect(repository.rules.length, provider.replaceRules.length);

    final rule = ReplaceRule(
      id: 'repository-rule',
      name: '测试规则',
      pattern: '旧内容',
    );
    await provider.addRule(rule);
    expect(provider.replaceRules.any((item) => item.id == rule.id), isTrue);
    expect(provider.processContent('旧内容'), '');

    await provider.toggleRule(rule.id, false);
    expect(
      provider.replaceRules.firstWhere((item) => item.id == rule.id).isEnabled,
      isFalse,
    );

    final updated = ReplaceRule(
      id: rule.id,
      name: rule.name,
      pattern: rule.pattern,
      replacement: '新内容',
      isEnabled: false,
    );
    await provider.updateRule(updated);
    expect(
      provider.replaceRules
          .firstWhere((item) => item.id == rule.id)
          .replacement,
      '新内容',
    );
    await provider.deleteRule(rule.id);
    expect(provider.replaceRules.any((item) => item.id == rule.id), isFalse);
  });
}
