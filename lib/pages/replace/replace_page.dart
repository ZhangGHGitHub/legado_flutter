import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/replace_rule.dart';
import '../../providers/library_provider.dart';

/// 替换净化页面 - 管理正则替换规则，去除广告
class ReplacePage extends StatefulWidget {
  const ReplacePage({super.key});

  @override
  State<ReplacePage> createState() => _ReplacePageState();
}

class _ReplacePageState extends State<ReplacePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('替换净化'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加规则',
            onPressed: () => _showRuleEditor(context, null),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'reset') {
                context.read<LibraryProvider>().resetReplaceRules();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reset', child: Text('恢复默认规则')),
            ],
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, _) {
          final rules = provider.replaceRules;

          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cleaning_services, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('暂无替换规则', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('点击右上角 + 添加', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.restore),
                    label: const Text('恢复默认规则'),
                    onPressed: () => provider.resetReplaceRules(),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 提示卡片
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20,
                        color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '替换规则会在阅读时自动应用到正文，可有效去除广告和无关内容。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...rules.map((rule) => _ReplaceRuleTile(rule: rule)),
            ],
          );
        },
      ),
    );
  }

  void _showRuleEditor(BuildContext context, ReplaceRule? rule) {
    final nameController = TextEditingController(text: rule?.name ?? '');
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    final replacementController = TextEditingController(text: rule?.replacement ?? '');
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
                  id: rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  pattern: patternController.text,
                  replacement: replacementController.text,
                  isRegex: isRegex,
                  isEnabled: rule?.isEnabled ?? true,
                );
                context.read<LibraryProvider>().saveReplaceRule(newRule);
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

class _ReplaceRuleTile extends StatelessWidget {
  final ReplaceRule rule;
  const _ReplaceRuleTile({required this.rule});

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
          onChanged: (v) {
            context.read<LibraryProvider>().toggleReplaceRule(rule.id, v);
          },
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除规则'),
              content: Text('确定删除「${rule.name}」？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<LibraryProvider>().deleteReplaceRule(rule.id);
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
