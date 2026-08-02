import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/replace/replace_notifier.dart';
import '../../application/replace/replace_preset_port.dart';
import '../../domain/content/replace_rule.dart';
import '../../providers/replace_provider.dart';
import '../../widgets/replace_preview_panel.dart';
import '../../widgets/legado_popup_menu.dart';

/// 替换净化页面 - 规则管理 + 实时预览 + 预设库
class ReplacePage extends StatelessWidget {
  const ReplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReplaceProvider>().controller;
    return riverpod.ProviderScope(
      overrides: [replaceRulesControllerProvider.overrideWithValue(controller)],
      child: const _ReplacePageBody(),
    );
  }
}

class _ReplacePageBody extends StatefulWidget {
  const _ReplacePageBody();

  @override
  State<_ReplacePageBody> createState() => _ReplacePageBodyState();
}

class _ReplacePageBodyState extends State<_ReplacePageBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('替换净化'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '规则列表', icon: Icon(Icons.list_alt, size: 20)),
            Tab(text: '实时预览', icon: Icon(Icons.preview, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: '导入预设规则',
            onPressed: () => _showPresetPicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加规则',
            onPressed: () => _showRuleEditor(context, null),
          ),
          PopupMenuButton<String>(
            offset: legadoAppBarPopupOffset(context),
            onSelected: (v) {
              if (v == 'reset') {
                riverpod.ProviderScope.containerOf(
                  context,
                ).read(replaceNotifierProvider.notifier).resetReplaceRules();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reset', child: Text('恢复默认规则')),
            ],
          ),
        ],
      ),
      body: riverpod.Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(replaceNotifierProvider);
          final notifier = ref.read(replaceNotifierProvider.notifier);
          final rules = state.rules;
          return TabBarView(
            controller: _tabController,
            children: [
              _RulesListTab(
                rules: rules,
                onEdit: (rule) => _showRuleEditor(context, rule),
                onReset: notifier.resetReplaceRules,
                onToggle: notifier.toggleRule,
                onDelete: notifier.deleteRule,
              ),
              ReplacePreviewPanel(
                rules: rules,
                applyRules: notifier.previewContent,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPresetPicker(BuildContext context) {
    final notifier = riverpod.ProviderScope.containerOf(
      context,
    ).read(replaceNotifierProvider.notifier);
    final presetPort = context.read<ReplacePresetPort>();
    final allPresets = presetPort.all;
    final groups = presetPort.grouped();
    final selected = <String>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '预设规则库',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheet(() {
                            if (selected.length == allPresets.length) {
                              selected.clear();
                            } else {
                              selected.addAll(allPresets.map((p) => p.id));
                            }
                          });
                        },
                        child: Text(
                          selected.length == allPresets.length ? '取消全选' : '全选',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: groups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),
                          ),
                          ...entry.value.map(
                            (preset) => CheckboxListTile(
                              value: selected.contains(preset.id),
                              onChanged: (v) {
                                setSheet(() {
                                  if (v == true) {
                                    selected.add(preset.id);
                                  } else {
                                    selected.remove(preset.id);
                                  }
                                });
                              },
                              title: Text(preset.name),
                              subtitle: Text(
                                preset.pattern.length > 48
                                    ? '${preset.pattern.substring(0, 48)}…'
                                    : preset.pattern,
                                style: const TextStyle(fontSize: 11),
                              ),
                              dense: true,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () async {
                            final presets = allPresets.where(
                              (p) => selected.contains(p.id),
                            );
                            final rules = presetPort.toRules(presets);
                            final added = await notifier.importPresets(rules);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('已导入 $added 条预设规则')),
                              );
                            }
                          },
                    child: Text('导入选中 (${selected.length})'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRuleEditor(BuildContext context, ReplaceRule? rule) {
    final notifier = riverpod.ProviderScope.containerOf(
      context,
    ).read(replaceNotifierProvider.notifier);
    final nameController = TextEditingController(text: rule?.name ?? '');
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    final replacementController = TextEditingController(
      text: rule?.replacement ?? '',
    );
    bool isRegex = rule?.isRegex ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(rule == null ? '添加规则' : '编辑规则'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '规则名称',
                    hintText: '例如：去除广告脚注',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: patternController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isRegex ? '正则表达式' : '文本',
                    hintText: isRegex ? r'例如：笔趣阁.*?阅读' : '要替换的文本',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replacementController,
                  decoration: const InputDecoration(
                    labelText: '替换为（留空即删除）',
                    hintText: '留空则匹配到的内容被删除',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('使用正则匹配'),
                  value: isRegex,
                  onChanged: (v) => setDialogState(() => isRegex = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final newRule = ReplaceRule(
                  id:
                      rule?.id ??
                      'rule_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  pattern: patternController.text,
                  replacement: replacementController.text,
                  isRegex: isRegex,
                  isEnabled: rule?.isEnabled ?? true,
                );
                if (rule == null) {
                  notifier.addRule(newRule);
                } else {
                  notifier.updateRule(newRule);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(rule == null ? '规则已添加' : '规则已更新')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesListTab extends StatelessWidget {
  const _RulesListTab({
    required this.rules,
    required this.onEdit,
    required this.onReset,
    required this.onToggle,
    required this.onDelete,
  });

  final List<ReplaceRule> rules;
  final void Function(ReplaceRule rule) onEdit;
  final VoidCallback onReset;
  final void Function(String ruleId, bool enabled) onToggle;
  final void Function(String ruleId) onDelete;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cleaning_services, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无替换规则', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 添加，或导入预设规则',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.restore),
              label: const Text('恢复默认规则'),
              onPressed: onReset,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '规则在阅读时自动应用。切换到「实时预览」可测试效果。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...rules.map(
          (rule) => _ReplaceRuleTile(
            rule: rule,
            onEdit: onEdit,
            onToggle: onToggle,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }
}

class _ReplaceRuleTile extends StatelessWidget {
  final ReplaceRule rule;
  final void Function(ReplaceRule rule) onEdit;
  final void Function(String ruleId, bool enabled) onToggle;
  final void Function(String ruleId) onDelete;

  const _ReplaceRuleTile({
    required this.rule,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rule.isEnabled
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[200],
          radius: 16,
          child: Icon(
            Icons.auto_fix_high,
            size: 18,
            color: rule.isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        title: Text(
          rule.name.isNotEmpty ? rule.name : '未命名规则',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: rule.isEnabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${rule.isRegex ? "正则" : "文本"}: ${rule.pattern.length > 30 ? "${rule.pattern.substring(0, 30)}..." : rule.pattern}',
          style: const TextStyle(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch(
          value: rule.isEnabled,
          onChanged: (v) => onToggle(rule.id, v),
        ),
        onTap: () => onEdit(rule),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除规则'),
              content: Text('确定删除「${rule.name}」？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDelete(rule.id);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
