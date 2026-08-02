import '../../domain/content/replace_rule.dart';
import '../../domain/ports/content_processing_port.dart';
import '../../domain/repositories/replace_rule_repository.dart';
import 'replace_preset_port.dart';
import 'replace_state.dart';

typedef ReplaceStateListener = void Function(ReplaceState state);

/// 替换规则的 application 状态控制器。
///
/// 旧 ChangeNotifier 和 Riverpod Notifier 共用此控制器，迁移期间只有一份
/// 规则状态，避免页面切换到 Riverpod 后出现两套列表。
final class ReplaceRulesController {
  ReplaceRulesController({
    required ReplaceRuleRepository repository,
    required ContentProcessingPort contentProcessor,
    ReplacePresetPort? presetPort,
  }) : _repository = repository,
       _contentProcessor = contentProcessor,
       _presetPort = presetPort ?? const UnavailableReplacePresetPort();

  final ReplaceRuleRepository _repository;
  final ContentProcessingPort _contentProcessor;
  final ReplacePresetPort _presetPort;
  final Set<ReplaceStateListener> _listeners = {};
  ReplaceState _state = const ReplaceState();

  ReplaceState get state => _state;
  List<ReplaceRule> get replaceRules => _state.rules;

  void addListener(ReplaceStateListener listener) => _listeners.add(listener);

  void removeListener(ReplaceStateListener listener) =>
      _listeners.remove(listener);

  Future<void> loadRules() async {
    var rules = await _repository.getAll();
    if (rules.isEmpty) {
      await _repository.insertAll(_presetPort.builtInRules());
      rules = await _repository.getAll();
    }
    _contentProcessor.loadRules(rules);
    _publish(rules);
  }

  Future<void> addRule(ReplaceRule rule) async {
    await _repository.insert(rule);
    await _reload();
  }

  Future<void> updateRule(ReplaceRule rule) async {
    await _repository.update(rule);
    await _reload();
  }

  Future<void> deleteRule(String ruleId) async {
    await _repository.delete(ruleId);
    await _reload();
  }

  Future<void> toggleRule(String ruleId, bool enabled) async {
    await _repository.toggle(ruleId, enabled);
    await _reload();
  }

  Future<void> resetReplaceRules() async {
    await _repository.clear();
    await _repository.insertAll(_presetPort.builtInRules());
    await _reload();
  }

  Future<int> importPresets(List<ReplaceRule> presets) async {
    final existingPatterns = _state.rules.map((rule) => rule.pattern).toSet();
    var added = 0;
    for (final rule in presets) {
      if (existingPatterns.contains(rule.pattern)) continue;
      await _repository.insert(rule);
      existingPatterns.add(rule.pattern);
      added++;
    }
    if (added > 0) await _reload();
    return added;
  }

  String processContent(String raw) => _contentProcessor.getContent(raw);

  String previewContent(String raw, List<ReplaceRule> rules) =>
      _contentProcessor.applyWithRules(raw, rules);

  Future<void> _reload() async {
    final rules = await _repository.getAll();
    _contentProcessor.loadRules(rules);
    _publish(rules);
  }

  void _publish(List<ReplaceRule> rules) {
    _state = ReplaceState(rules: List.unmodifiable(rules));
    for (final listener in List<ReplaceStateListener>.of(_listeners)) {
      listener(_state);
    }
  }
}
