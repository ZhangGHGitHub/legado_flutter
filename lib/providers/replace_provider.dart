import 'package:flutter/foundation.dart';
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
  }) : _repository = repository,
       _contentProcessor = contentProcessor,
       _presetPort = presetPort ?? const UnavailableReplacePresetPort();

  final ReplaceRuleRepository _repository;
  final ContentProcessingPort _contentProcessor;
  final ReplacePresetPort _presetPort;
  List<ReplaceRule> _replaceRules = [];

  List<ReplaceRule> get replaceRules => _replaceRules;

  /// 加载替换规则（首次运行时初始化默认规则）
  Future<void> loadRules() async {
    _replaceRules = await _repository.getAll();
    if (_replaceRules.isEmpty) {
      await _repository.insertAll(_presetPort.builtInRules());
      _replaceRules = await _repository.getAll();
    }
    _contentProcessor.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 添加规则
  Future<void> addRule(ReplaceRule rule) async {
    await _repository.insert(rule);
    _replaceRules = await _repository.getAll();
    _contentProcessor.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 更新规则
  Future<void> updateRule(ReplaceRule rule) async {
    await _repository.update(rule);
    _replaceRules = await _repository.getAll();
    _contentProcessor.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 删除规则
  Future<void> deleteRule(String ruleId) async {
    await _repository.delete(ruleId);
    _replaceRules = await _repository.getAll();
    _contentProcessor.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 启用/禁用规则
  Future<void> toggleRule(String ruleId, bool enabled) async {
    await _repository.toggle(ruleId, enabled);
    _replaceRules = await _repository.getAll();
    _contentProcessor.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 重置为默认规则
  Future<void> resetReplaceRules() async {
    await _repository.clear();
    await _repository.insertAll(_presetPort.builtInRules());
    _replaceRules = await _repository.getAll();
    _contentProcessor.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 导入预设规则（按 pattern 去重，已存在则跳过）
  Future<int> importPresets(List<ReplaceRule> presets) async {
    final existingPatterns = _replaceRules.map((r) => r.pattern).toSet();
    var added = 0;
    for (final rule in presets) {
      if (existingPatterns.contains(rule.pattern)) continue;
      await _repository.insert(rule);
      existingPatterns.add(rule.pattern);
      added++;
    }
    if (added > 0) {
      _replaceRules = await _repository.getAll();
      _contentProcessor.loadRules(_replaceRules);
      notifyListeners();
    }
    return added;
  }

  String processContent(String raw) => _contentProcessor.getContent(raw);

  String previewContent(String raw, List<ReplaceRule> rules) {
    return _contentProcessor.applyWithRules(raw, rules);
  }
}
