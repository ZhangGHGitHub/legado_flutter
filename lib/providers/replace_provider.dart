import 'package:flutter/foundation.dart';
import '../models/replace_rule.dart';
import '../database/database_helper.dart';
import '../help/content_processor.dart';
import '../services/replace_service.dart';

/// 替换净化 Provider — 替换规则管理
class ReplaceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ReplaceService _replaceService = ReplaceService();

  List<ReplaceRule> _replaceRules = [];

  List<ReplaceRule> get replaceRules => _replaceRules;
  ReplaceService get replaceService => _replaceService;

  /// 加载替换规则（首次运行时初始化默认规则）
  Future<void> loadRules() async {
    _replaceRules = await _db.getReplaceRules();
    if (_replaceRules.isEmpty) {
      await _db.insertReplaceRules(ReplaceService.builtInRules());
      _replaceRules = await _db.getReplaceRules();
    }
    _replaceService.loadRules(_replaceRules);
    ContentProcessor.instance.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 添加规则
  Future<void> addRule(ReplaceRule rule) async {
    await _db.insertReplaceRule(rule);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    ContentProcessor.instance.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 更新规则
  Future<void> updateRule(ReplaceRule rule) async {
    await _db.updateReplaceRule(rule);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    ContentProcessor.instance.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 删除规则
  Future<void> deleteRule(String ruleId) async {
    await _db.deleteReplaceRule(ruleId);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    ContentProcessor.instance.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 启用/禁用规则
  Future<void> toggleRule(String ruleId, bool enabled) async {
    await _db.toggleReplaceRule(ruleId, enabled);
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    ContentProcessor.instance.loadRules(_replaceRules);
    notifyListeners();
  }

  /// 重置为默认规则
  Future<void> resetReplaceRules() async {
    await _db.clearReplaceRules();
    await _db.insertReplaceRules(ReplaceService.builtInRules());
    _replaceRules = await _db.getReplaceRules();
    _replaceService.loadRules(_replaceRules);
    ContentProcessor.instance.loadRules(_replaceRules);
    notifyListeners();
  }
}
