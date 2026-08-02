import 'package:flutter/foundation.dart';
import '../application/replace/replace_controller.dart';
import '../application/replace/replace_preset_port.dart';
import '../domain/content/replace_rule.dart';
import '../domain/ports/content_processing_port.dart';
import '../domain/repositories/replace_rule_repository.dart';

/// 替换净化 Provider — 替换规则管理
class ReplaceProvider extends ChangeNotifier {
  ReplaceProvider({
    required ReplaceRuleRepository repository,
    required ContentProcessingPort contentProcessor,
    ReplacePresetPort? presetPort,
    ReplaceRulesController? controller,
  }) : _controller =
           controller ??
           ReplaceRulesController(
             repository: repository,
             contentProcessor: contentProcessor,
             presetPort: presetPort,
           ) {
    _controller.addListener(_onControllerStateChanged);
  }

  final ReplaceRulesController _controller;

  ReplaceRulesController get controller => _controller;

  List<ReplaceRule> get replaceRules => _controller.replaceRules;

  /// 加载替换规则（首次运行时初始化默认规则）
  Future<void> loadRules() => _controller.loadRules();

  /// 添加规则
  Future<void> addRule(ReplaceRule rule) => _controller.addRule(rule);

  /// 更新规则
  Future<void> updateRule(ReplaceRule rule) => _controller.updateRule(rule);

  /// 删除规则
  Future<void> deleteRule(String ruleId) => _controller.deleteRule(ruleId);

  /// 启用/禁用规则
  Future<void> toggleRule(String ruleId, bool enabled) =>
      _controller.toggleRule(ruleId, enabled);

  /// 重置为默认规则
  Future<void> resetReplaceRules() => _controller.resetReplaceRules();

  /// 导入预设规则（按 pattern 去重，已存在则跳过）
  Future<int> importPresets(List<ReplaceRule> presets) =>
      _controller.importPresets(presets);

  String processContent(String raw) => _controller.processContent(raw);

  String previewContent(String raw, List<ReplaceRule> rules) =>
      _controller.previewContent(raw, rules);

  void _onControllerStateChanged(_) => notifyListeners();

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    super.dispose();
  }
}
