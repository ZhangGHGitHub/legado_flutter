import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content/replace_rule.dart';
import 'replace_controller.dart';
import 'replace_state.dart';

/// Riverpod 迁移期间由页面局部覆盖为组合根创建的共享控制器。
final replaceRulesControllerProvider = Provider<ReplaceRulesController>(
  (ref) => throw StateError('未提供 ReplaceRulesController'),
);

final replaceNotifierProvider = NotifierProvider<ReplaceNotifier, ReplaceState>(
  ReplaceNotifier.new,
);

/// 替换规则页面的生产状态入口。
class ReplaceNotifier extends Notifier<ReplaceState> {
  late ReplaceRulesController _controller;

  @override
  ReplaceState build() {
    _controller = ref.watch(replaceRulesControllerProvider);
    void onStateChanged(ReplaceState next) {
      state = next;
    }

    _controller.addListener(onStateChanged);
    ref.onDispose(() => _controller.removeListener(onStateChanged));
    return _controller.state;
  }

  Future<void> loadRules() => _controller.loadRules();

  Future<void> addRule(ReplaceRule rule) => _controller.addRule(rule);

  Future<void> updateRule(ReplaceRule rule) => _controller.updateRule(rule);

  Future<void> deleteRule(String ruleId) => _controller.deleteRule(ruleId);

  Future<void> toggleRule(String ruleId, bool enabled) =>
      _controller.toggleRule(ruleId, enabled);

  Future<void> resetReplaceRules() => _controller.resetReplaceRules();

  Future<int> importPresets(List<ReplaceRule> presets) =>
      _controller.importPresets(presets);

  String processContent(String raw) => _controller.processContent(raw);

  String previewContent(String raw, List<ReplaceRule> rules) =>
      _controller.previewContent(raw, rules);
}
