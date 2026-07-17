import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_log.dart';
import '../../services/reader_font_loader.dart';

/// 应用日志 Dialog — 对齐 Jingshiro [AppLogDialog]（清空；最新在前）。
class AppLogDialog extends StatefulWidget {
  const AppLogDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AppLogDialog(),
    );
  }

  @override
  State<AppLogDialog> createState() => _AppLogDialogState();
}

class _AppLogDialogState extends State<AppLogDialog> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    AppLog.ensureLoaded().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _copyAll() async {
    final text = AppLog.entries.map((e) => e.line).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制全部日志')),
      );
    }
  }

  Future<void> _clear() async {
    await AppLog.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: ReaderFontLoader.platformSansFamily(),
      fontFamilyFallback: ReaderFontLoader.cjkFallbackFamilies(),
      fontSize: 12,
      height: 1.35,
    );
    final entries = AppLog.entries;
    final size = MediaQuery.sizeOf(context);

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('日志')),
          IconButton(
            tooltip: '复制',
            onPressed: entries.isEmpty ? null : _copyAll,
            icon: const Icon(Icons.copy, size: 20),
          ),
          IconButton(
            tooltip: '清空',
            onPressed: entries.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: size.width * 0.85,
        height: size.height * 0.55,
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
                ? const Center(child: Text('暂无日志'))
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      final color = switch (e.level) {
                        'E' => Theme.of(ctx).colorScheme.error,
                        'W' => Colors.orange.shade800,
                        _ => Theme.of(ctx).colorScheme.onSurface,
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: SelectableText(
                          e.line,
                          style: style.copyWith(color: color),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
