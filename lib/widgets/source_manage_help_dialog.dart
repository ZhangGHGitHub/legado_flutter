import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 书源管理帮助 — 轻量 md 渲染（# 标题、* 列表），无 flutter_markdown
class SourceManageHelpDialog extends StatelessWidget {
  const SourceManageHelpDialog({super.key, required this.content});

  static const assetPath = 'assets/help/SourceMBookHelp.md';

  static Future<void> show(BuildContext context) async {
    final content = await rootBundle.loadString(assetPath);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => SourceManageHelpDialog(content: content),
    );
  }

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('书源管理帮助'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _parseLines(content, theme),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }

  static List<Widget> _parseLines(String md, ThemeData theme) {
    final widgets = <Widget>[];
    for (final raw in md.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.substring(2),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        continue;
      }
      if (line.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text('• ${line.substring(2)}', style: theme.textTheme.bodyMedium),
          ),
        );
        continue;
      }
      if (line.startsWith(' * ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 2),
            child: Text(
              '◦ ${line.substring(3)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
        continue;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(line, style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return widgets;
  }
}
