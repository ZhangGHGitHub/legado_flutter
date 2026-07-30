import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/diagnostics/app_log_port.dart';
import '../../services/clipboard_port.dart';
import '../../services/reader_font_loader.dart';

/// 应用日志页 — 对齐 Jingshiro [AppLogDialog]
class AppLogPage extends StatefulWidget {
  const AppLogPage({super.key, this.clipboard, this.log});

  final ClipboardPort? clipboard;
  final AppLogPort? log;

  @override
  State<AppLogPage> createState() => _AppLogPageState();
}

class _AppLogPageState extends State<AppLogPage> {
  bool _ready = false;
  late final AppLogPort _log;

  @override
  void initState() {
    super.initState();
    _log = widget.log ?? context.read<AppLogPort>();
    _log.ensureLoaded().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _copyAll() async {
    final text = _log.exportText();
    await (widget.clipboard ?? const PlatformClipboard()).copyText(text);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制全部日志')));
    }
  }

  Future<void> _clear() async {
    await _log.clear();
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
    final entries = _log.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          IconButton(
            tooltip: '复制',
            onPressed: entries.isEmpty ? null : _copyAll,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: '清空',
            onPressed: entries.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? const Center(child: Text('暂无日志'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final e = entries[i];
                final color = switch (e.severity.level) {
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
    );
  }
}
