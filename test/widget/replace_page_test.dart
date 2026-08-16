import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/replace/replace_controller.dart';
import 'package:legado_flutter/application/replace/replace_notifier.dart';
import 'package:legado_flutter/application/replace/replace_preset.dart';
import 'package:legado_flutter/application/replace/replace_preset_port.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/features/my/replace_page.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ReplacePage consumes the parent controller scope', (
    tester,
  ) async {
    final repository = _MemoryReplaceRuleRepository([
      const ReplaceRule(id: 'rule-1', name: '去广告', pattern: '广告内容'),
    ]);
    final controller = _createController(repository);
    await controller.loadRules();

    await tester.pumpWidget(
      Provider<ReplacePresetPort>.value(
        value: const _FakeReplacePresetPort(),
        child: riverpod.ProviderScope(
          overrides: [
            replaceRulesControllerProvider.overrideWithValue(controller),
          ],
          child: const MaterialApp(home: ReplacePage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('去广告'), findsOneWidget);
    expect(find.textContaining('正则: 广告内容'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.preview));
    await tester.pumpAndSettle();
    expect(find.text('测试文本'), findsOneWidget);
    expect(find.text('替换结果'), findsOneWidget);
  });

  testWidgets('ReplacePage supports an explicitly injected independent host', (
    tester,
  ) async {
    final repository = _MemoryReplaceRuleRepository();
    final controller = _createController(repository);

    await tester.pumpWidget(
      Provider<ReplacePresetPort>.value(
        value: const _FakeReplacePresetPort(),
        child: riverpod.ProviderScope(
          child: MaterialApp(home: ReplacePage(controller: controller)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('暂无替换规则'), findsOneWidget);
    await tester.tap(find.text('恢复默认规则'));
    await tester.pumpAndSettle();
    expect(find.text('默认规则'), findsOneWidget);

    await tester.tap(find.byTooltip('导入预设规则'));
    await tester.pumpAndSettle();
    expect(find.text('预设去广告'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('导入选中 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('预设去广告'), findsOneWidget);

    await tester.tap(find.byTooltip('添加规则'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '新增规则');
    await tester.enterText(fields.at(1), '旧文本');
    await tester.enterText(fields.at(2), '新文本');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('新增规则'), findsOneWidget);

    await tester.tap(find.text('新增规则'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '修改规则');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('修改规则'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(
      repository.rules.singleWhere((rule) => rule.name == '修改规则').isEnabled,
      isFalse,
    );

    await tester.longPress(find.text('修改规则'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('修改规则'), findsNothing);
  });
}

ReplaceRulesController _createController(_MemoryReplaceRuleRepository repo) {
  return ReplaceRulesController(
    repository: repo,
    contentProcessor: ContentProcessorAdapter(),
    presetPort: const _FakeReplacePresetPort(),
  );
}

final class _MemoryReplaceRuleRepository implements ReplaceRuleRepository {
  _MemoryReplaceRuleRepository([List<ReplaceRule>? initial])
    : rules = List<ReplaceRule>.of(initial ?? const []);

  final List<ReplaceRule> rules;

  @override
  Future<List<ReplaceRule>> getAll() async => List<ReplaceRule>.of(rules);

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
    if (index >= 0) rules[index] = rules[index].copyWith(isEnabled: enabled);
  }

  @override
  Future<void> delete(String ruleId) async {
    rules.removeWhere((rule) => rule.id == ruleId);
  }

  @override
  Future<void> clear() async => rules.clear();
}

final class _FakeReplacePresetPort implements ReplacePresetPort {
  const _FakeReplacePresetPort();

  static const _default = ReplaceRule(
    id: 'default-rule',
    name: '默认规则',
    pattern: '默认广告',
  );
  static const _preset = ReplacePreset(
    id: 'preset-ad',
    category: '测试',
    name: '预设去广告',
    pattern: '预设广告',
  );

  @override
  List<ReplaceRule> builtInRules() => const [_default];

  @override
  List<ReplacePreset> get all => const [_preset];

  @override
  Map<String, List<ReplacePreset>> grouped() => const {
    '测试': [_preset],
  };

  @override
  List<ReplaceRule> toRules(Iterable<ReplacePreset> presets) =>
      presets.map((preset) => preset.toRule()).toList();
}
