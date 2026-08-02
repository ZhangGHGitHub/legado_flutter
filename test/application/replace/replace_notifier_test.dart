import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/replace/replace_controller.dart';
import 'package:legado_flutter/application/replace/replace_notifier.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';

void main() {
  test('Riverpod notifier mirrors the shared controller state', () async {
    final repository = _FakeReplaceRuleRepository();
    final controller = ReplaceRulesController(
      repository: repository,
      contentProcessor: ContentProcessorAdapter(),
    );
    final container = ProviderContainer(
      overrides: [replaceRulesControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(replaceNotifierProvider.notifier);
    final load = notifier.loadRules();
    expect(container.read(replaceNotifierProvider).rules, isEmpty);
    await load;

    expect(container.read(replaceNotifierProvider).rules, isEmpty);
    await controller.addRule(
      const ReplaceRule(id: 'riverpod-rule', name: '测试', pattern: '旧内容'),
    );
    expect(
      container.read(replaceNotifierProvider).rules.single.id,
      'riverpod-rule',
    );
  });
}

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
    rules[index] = rules[index].copyWith(isEnabled: enabled);
  }

  @override
  Future<void> delete(String ruleId) async {
    rules.removeWhere((rule) => rule.id == ruleId);
  }

  @override
  Future<void> clear() async => rules.clear();
}
