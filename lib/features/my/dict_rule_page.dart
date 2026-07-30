import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/dictionary/dict_rule_tester.dart';
import '../../application/platform/clipboard_port.dart';
import '../../application/preferences/dict_rule_prefs_port.dart';
import '../../domain/ports/dict_rule_query_port.dart';
import '../../domain/rules/dict_rule.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/legado_popup_menu.dart';

/// 字典规则管理 — 对齐 Jingshiro [DictRuleActivity]
class DictRulePage extends StatefulWidget {
  const DictRulePage({super.key});

  @override
  State<DictRulePage> createState() => _DictRulePageState();
}

class _DictRulePageState extends State<DictRulePage> {
  List<DictRule> _rules = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await context.read<DictRulePrefsPort>().load();
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _loading = false;
      _selected.removeWhere((name) => !_rules.any((r) => r.name == name));
    });
  }

  Future<void> _persist() async {
    await context.read<DictRulePrefsPort>().save(_rules);
    if (mounted) setState(() {});
  }

  Future<void> _toggleEnable(DictRule rule, bool enable) async {
    final i = _rules.indexWhere((r) => r.name == rule.name);
    if (i < 0) return;
    setState(() => _rules[i] = rule.copyWith(enabled: enable));
    await _persist();
  }

  Future<void> _deleteRules(Iterable<DictRule> targets) async {
    final names = targets.map((e) => e.name).toSet();
    setState(() {
      _rules.removeWhere((r) => names.contains(r.name));
      _selected.removeAll(names);
      if (_selected.isEmpty) _selectionMode = false;
    });
    await _persist();
  }

  Future<void> _confirmDelete(DictRule rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除'),
        content: Text('确定删除\n${rule.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteRules([rule]);
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除'),
        content: Text('确定删除选中的 ${_selected.length} 条规则？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _deleteRules(_rules.where((r) => _selected.contains(r.name)));
  }

  Future<void> _setSelectedEnable(bool enable) async {
    setState(() {
      _rules = _rules
          .map(
            (r) => _selected.contains(r.name) ? r.copyWith(enabled: enable) : r,
          )
          .toList();
    });
    await _persist();
  }

  Future<void> _saveRule(DictRule rule, {String? oldName}) async {
    setState(() {
      if (oldName != null) {
        final i = _rules.indexWhere((r) => r.name == oldName);
        if (i >= 0) {
          // rename: drop any conflict with new name first
          _rules.removeWhere((r) => r.name == rule.name && r.name != oldName);
          _rules[i] = rule;
        } else {
          _rules.removeWhere((r) => r.name == rule.name);
          _rules.add(rule);
        }
      } else {
        final i = _rules.indexWhere((r) => r.name == rule.name);
        if (i >= 0) {
          _rules[i] = rule;
        } else {
          final maxOrder = _rules.isEmpty
              ? -1
              : _rules.map((r) => r.sortNumber).reduce((a, b) => a > b ? a : b);
          _rules.add(rule.copyWith(sortNumber: maxOrder + 1));
        }
      }
      _rules.sort((a, b) => a.sortNumber.compareTo(b.sortNumber));
      if (oldName != null && oldName != rule.name) {
        _selected.remove(oldName);
      }
    });
    await _persist();
  }

  Future<void> _showEditDialog([DictRule? existing]) async {
    final saved = await showDialog<_DictRuleEditResult>(
      context: context,
      builder: (_) => _DictRuleEditDialog(rule: existing),
    );
    if (saved != null) {
      await _saveRule(saved.rule, oldName: saved.oldName);
    }
  }

  void _toggleSelect(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
      _selectionMode = _selected.isNotEmpty;
    });
  }

  void _selectAll(bool all) {
    setState(() {
      if (all) {
        _selected
          ..clear()
          ..addAll(_rules.map((r) => r.name));
        _selectionMode = true;
      } else {
        _selected.clear();
        _selectionMode = false;
      }
    });
  }

  Future<void> _importDefaults() async {
    final existing = _rules.map((r) => r.name).toSet();
    final toAdd = context
        .read<DictRulePrefsPort>()
        .defaultRules
        .where((r) => !existing.contains(r.name))
        .toList();
    if (toAdd.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('内置规则已全部存在')));
      return;
    }
    setState(() {
      _rules = [..._rules, ...toAdd]
        ..sort((a, b) => a.sortNumber.compareTo(b.sortNumber));
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已导入 ${toAdd.length} 条内置规则')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('字典规则'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加',
            onPressed: () => _showEditDialog(),
          ),
          PopupMenuButton<String>(
            offset: legadoAppBarPopupOffset(context),
            onSelected: (v) async {
              switch (v) {
                case 'defaults':
                  await _importDefaults();
                case 'reset':
                  await context.read<DictRulePrefsPort>().resetToDefaults();
                  await _load();
                case 'select':
                  _selectAll(_selected.length != _rules.length);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'defaults', child: Text('导入内置规则')),
              PopupMenuItem(value: 'reset', child: Text('恢复默认规则')),
              PopupMenuItem(value: 'select', child: Text('全选/取消全选')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
          ? EmptyState(
              icon: Icons.menu_book_outlined,
              title: '暂无字典规则',
              subtitle: '添加查词 URL / 显示规则',
              actionLabel: '导入内置规则',
              onAction: _importDefaults,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: _rules.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      final selected = _selected.contains(rule.name);
                      return InkWell(
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelect(rule.name);
                          } else {
                            _showEditDialog(rule);
                          }
                        },
                        onLongPress: () => _toggleSelect(rule.name),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: (_) => _toggleSelect(rule.name),
                              ),
                              Expanded(
                                child: Text(
                                  rule.name,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Switch(
                                value: rule.enabled,
                                onChanged: (v) => _toggleEnable(rule, v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: '编辑',
                                onPressed: () => _showEditDialog(rule),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: '删除',
                                onPressed: () => _confirmDelete(rule),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  switch (v) {
                                    case 'top':
                                      setState(() {
                                        _rules.remove(rule);
                                        _rules.insert(0, rule);
                                        for (
                                          var i = 0;
                                          i < _rules.length;
                                          i++
                                        ) {
                                          _rules[i] = _rules[i].copyWith(
                                            sortNumber: i,
                                          );
                                        }
                                      });
                                      await _persist();
                                    case 'bottom':
                                      setState(() {
                                        _rules.remove(rule);
                                        _rules.add(rule);
                                        for (
                                          var i = 0;
                                          i < _rules.length;
                                          i++
                                        ) {
                                          _rules[i] = _rules[i].copyWith(
                                            sortNumber: i,
                                          );
                                        }
                                      });
                                      await _persist();
                                    case 'copy':
                                      await context
                                          .read<ClipboardPort>()
                                          .copyText(jsonEncode(rule.toJson()));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('已复制规则摘要'),
                                          ),
                                        );
                                      }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'top',
                                    child: Text('置顶'),
                                  ),
                                  PopupMenuItem(
                                    value: 'bottom',
                                    child: Text('置底'),
                                  ),
                                  PopupMenuItem(
                                    value: 'copy',
                                    child: Text('复制'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectionMode) _buildSelectBar(theme),
              ],
            ),
    );
  }

  Widget _buildSelectBar(ThemeData theme) {
    final allSelected = _rules.isNotEmpty && _selected.length == _rules.length;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                tristate: true,
                onChanged: (v) => _selectAll(v == true),
              ),
              Expanded(
                child: Text(
                  '已选 ${_selected.length}/${_rules.length}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => _setSelectedEnable(true),
                child: const Text('启用'),
              ),
              TextButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => _setSelectedEnable(false),
                child: const Text('禁用'),
              ),
              FilledButton(
                onPressed: _selected.isEmpty ? null : _confirmDeleteSelected,
                child: const Text('删除'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DictRuleEditResult {
  final DictRule rule;
  final String? oldName;

  const _DictRuleEditResult({required this.rule, this.oldName});
}

class _DictRuleEditDialog extends StatefulWidget {
  const _DictRuleEditDialog({this.rule});

  final DictRule? rule;

  @override
  State<_DictRuleEditDialog> createState() => _DictRuleEditDialogState();
}

class _DictRuleEditDialogState extends State<_DictRuleEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _urlRule;
  late final TextEditingController _showRule;
  late final TextEditingController _testWord;
  String? _error;
  String? _testResult;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _name = TextEditingController(text: r?.name ?? '');
    _urlRule = TextEditingController(text: r?.urlRule ?? '');
    _showRule = TextEditingController(text: r?.showRule ?? '');
    _testWord = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _urlRule.dispose();
    _showRule.dispose();
    _testWord.dispose();
    super.dispose();
  }

  DictRule _draft() {
    final existing = widget.rule;
    return DictRule(
      name: _name.text.trim(),
      urlRule: _urlRule.text,
      showRule: _showRule.text,
      enabled: existing?.enabled ?? true,
      sortNumber: existing?.sortNumber ?? 0,
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '名称不能为空');
      return;
    }
    Navigator.pop(
      context,
      _DictRuleEditResult(rule: _draft(), oldName: widget.rule?.name),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _error = null;
      _testing = true;
      _testResult = null;
    });
    try {
      final result = await DictRuleTester(
        context.read<DictRuleQueryPort>(),
      ).test(_draft(), _testWord.text);
      if (!mounted) return;
      setState(() {
        _testResult = result;
        _testing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? '添加规则' : '编辑规则'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlRule,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'URL规则',
                  border: OutlineInputBorder(),
                  helperText: '支持 {{key}}；可选 ,{"method":"POST",...}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _showRule,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '显示规则',
                  border: OutlineInputBorder(),
                  helperText: '为空则直接显示响应；@js 需完整规则引擎',
                ),
              ),
              const SizedBox(height: 16),
              Text('规则测试', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _testWord,
                      decoration: const InputDecoration(
                        labelText: '测试词',
                        border: OutlineInputBorder(),
                        hintText: '输入要查询的词',
                      ),
                      onSubmitted: (_) => _runTest(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _testing ? null : _runTest,
                    child: _testing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('测试'),
                  ),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _testResult!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
