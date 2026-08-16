import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/replace/replace_controller.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/infrastructure/replace/replace_preset_port_adapter.dart';

void main() {
  test('loads built-ins and publishes an immutable state', () async {
    final repository = _FakeReplaceRuleRepository();
    final controller = ReplaceRulesController(
      repository: repository,
      contentProcessor: ContentProcessorAdapter(),
      presetPort: const ReplacePresetPortAdapter(),
    );
    var notifications = 0;
    controller.addListener((_) => notifications++);

    await controller.loadRules();

    expect(controller.replaceRules, isNotEmpty);
    expect(notifications, 1);
    expect(
      () => controller.replaceRules.add(
        const ReplaceRule(id: 'x', name: 'x', pattern: 'x'),
      ),
      throwsUnsupportedError,
    );
  });

  test(
    'keeps CRUD and preset deduplication in the shared controller',
    () async {
      final repository = _FakeReplaceRuleRepository();
      final controller = ReplaceRulesController(
        repository: repository,
        contentProcessor: ContentProcessorAdapter(),
        presetPort: const ReplacePresetPortAdapter(),
      );
      await controller.loadRules();
      final rule = const ReplaceRule(
        id: 'controller-rule',
        name: '测试规则',
        pattern: '旧内容',
      );

      await controller.addRule(rule);
      expect(controller.processContent('旧内容'), '');
      expect(await controller.importPresets([rule]), 0);
      await controller.toggleRule(rule.id, false);
      expect(
        controller.replaceRules
            .singleWhere((item) => item.id == rule.id)
            .isEnabled,
        isFalse,
      );
      await controller.deleteRule(rule.id);
      expect(
        controller.replaceRules.any((item) => item.id == rule.id),
        isFalse,
      );
    },
  );
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
    final rule = rules[index];
    rules[index] = rule.copyWith(isEnabled: enabled);
  }

  @override
  Future<void> delete(String ruleId) async {
    rules.removeWhere((rule) => rule.id == ruleId);
  }

  @override
  Future<void> clear() async => rules.clear();
}
