import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/platform/clipboard_port.dart';
import '../../application/preferences/txt_toc_rule_prefs_port.dart';
import '../../application/rules/txt_toc_rule_creation_policy.dart';
import '../../domain/rules/txt_toc_rule.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/legado_popup_menu.dart';

/// TXT 目录规则管理 — 对齐 Jingshiro [TxtTocRuleActivity]
class TxtTocRulePage extends StatefulWidget {
  const TxtTocRulePage({super.key});

  @override
  State<TxtTocRulePage> createState() => _TxtTocRulePageState();
}

class _TxtTocRulePageState extends State<TxtTocRulePage> {
  List<TxtTocRule> _rules = [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rules = await context.read<TxtTocRulePrefsPort>().load();
    if (!mounted) return;
    setState(() {
      _rules = rules;
      _loading = false;
      _selected.removeWhere((id) => !_rules.any((r) => r.id == id));
    });
  }

  Future<void> _persist() async {
    await context.read<TxtTocRulePrefsPort>().save(_rules);
    if (mounted) setState(() {});
  }

  Future<void> _toggleEnable(TxtTocRule rule, bool enable) async {
    final i = _rules.indexWhere((r) => r.id == rule.id);
    if (i < 0) return;
    setState(() => _rules[i] = rule.copyWith(enable: enable));
    await _persist();
  }

  Future<void> _deleteRules(Iterable<TxtTocRule> targets) async {
    final ids = targets.map((e) => e.id).toSet();
    setState(() {
      _rules.removeWhere((r) => ids.contains(r.id));
      _selected.removeAll(ids);
      if (_selected.isEmpty) _selectionMode = false;
    });
    await _persist();
  }

  Future<void> _confirmDelete(TxtTocRule rule) async {
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
    await _deleteRules(_rules.where((r) => _selected.contains(r.id)));
  }

  Future<void> _setSelectedEnable(bool enable) async {
    setState(() {
      _rules = _rules
          .map((r) => _selected.contains(r.id) ? r.copyWith(enable: enable) : r)
          .toList();
    });
    await _persist();
  }

  Future<void> _saveRule(TxtTocRule rule) async {
    final i = _rules.indexWhere((r) => r.id == rule.id);
    setState(() {
      if (i >= 0) {
        _rules[i] = rule;
      } else {
        final maxOrder = _rules.isEmpty
            ? -1
            : _rules.map((r) => r.serialNumber).reduce((a, b) => a > b ? a : b);
        _rules.add(rule.copyWith(serialNumber: maxOrder + 1));
      }
      _rules.sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
    });
    await _persist();
  }

  Future<void> _showEditDialog([TxtTocRule? existing]) async {
    final saved = await showDialog<TxtTocRule>(
      context: context,
      builder: (_) => _TxtTocRuleEditDialog(rule: existing),
    );
    if (saved != null) await _saveRule(saved);
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _selectionMode = _selected.isNotEmpty;
    });
  }

  void _selectAll(bool all) {
    setState(() {
      if (all) {
        _selected
          ..clear()
          ..addAll(_rules.map((r) => r.id));
        _selectionMode = true;
      } else {
        _selected.clear();
        _selectionMode = false;
      }
    });
  }

  Future<void> _importDefaults() async {
    final existingIds = _rules.map((r) => r.id).toSet();
    final toAdd = context
        .read<TxtTocRulePrefsPort>()
        .defaultRules
        .where((r) => !existingIds.contains(r.id))
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
        ..sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
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
        title: const Text('TXT目录规则'),
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
                  await context.read<TxtTocRulePrefsPort>().resetToDefaults();
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
              icon: Icons.article_outlined,
              title: '暂无目录规则',
              subtitle: '添加正则以识别 TXT 章节标题',
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
                      final selected = _selected.contains(rule.id);
                      return InkWell(
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelect(rule.id);
                          } else {
                            _showEditDialog(rule);
                          }
                        },
                        onLongPress: () => _toggleSelect(rule.id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleSelect(rule.id),
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
                                    value: rule.enable,
                                    onChanged: (v) => _toggleEnable(rule, v),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: '编辑',
                                    onPressed: () => _showEditDialog(rule),
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
                                                serialNumber: i,
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
                                                serialNumber: i,
                                              );
                                            }
                                          });
                                          await _persist();
                                        case 'copy':
                                          await context
                                              .read<ClipboardPort>()
                                              .copyText(rule.rule);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('已复制正则'),
                                              ),
                                            );
                                          }
                                        case 'delete':
                                          await _confirmDelete(rule);
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
                                        child: Text('复制正则'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('删除'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (rule.example != null &&
                                  rule.example!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 48,
                                    right: 8,
                                    top: 2,
                                  ),
                                  child: Text(
                                    rule.example!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

class _TxtTocRuleEditDialog extends StatefulWidget {
  const _TxtTocRuleEditDialog({this.rule});

  final TxtTocRule? rule;

  @override
  State<_TxtTocRuleEditDialog> createState() => _TxtTocRuleEditDialogState();
}

class _TxtTocRuleEditDialogState extends State<_TxtTocRuleEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _rule;
  late final TextEditingController _replacement;
  late final TextEditingController _example;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _name = TextEditingController(text: r?.name ?? '');
    _rule = TextEditingController(text: r?.rule ?? '');
    _replacement = TextEditingController(text: r?.replacement ?? '');
    _example = TextEditingController(text: r?.example ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _rule.dispose();
    _replacement.dispose();
    _example.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '名称不能为空');
      return;
    }
    final pattern = _rule.text;
    if (pattern.trim().isNotEmpty) {
      try {
        RegExp(pattern, multiLine: true);
      } catch (e) {
        setState(() => _error = '正则语法错误或不支持：$e');
        return;
      }
    }
    final existing = widget.rule;
    Navigator.pop(
      context,
      TxtTocRuleCreationPolicy.fromEditor(
        existing: existing,
        name: name,
        rule: pattern,
        replacement: _replacement.text,
        example: _example.text.isEmpty ? null : _example.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? '添加规则' : '编辑规则'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                controller: _rule,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '正则',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _replacement,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '替换为(JS)',
                  border: OutlineInputBorder(),
                  helperText: '可选；高级替换/JS，分章时主要使用正则',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _example,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '示例',
                  border: OutlineInputBorder(),
                ),
              ),
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
