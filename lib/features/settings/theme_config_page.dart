import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/ports/public_text_fetch_port.dart';
import '../../application/platform/clipboard_port.dart';
import '../../services/theme_import_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/color_presets.dart';
import '../../widgets/theme_color_editor.dart';
import '../../features/reader/reader_settings.dart';

/// 主题设置 — MD3 预设 + 12 色板 + 导入/市场（Phase 4.1）
class ThemeConfigPage extends StatefulWidget {
  const ThemeConfigPage({super.key});

  @override
  State<ThemeConfigPage> createState() => _ThemeConfigPageState();
}

class _ThemeConfigPageState extends State<ThemeConfigPage> {
  final _importService = const ThemeImportService();
  final _marketUrlCtrl = TextEditingController();
  final _clipboardCtrl = TextEditingController();
  bool _loadingMarket = false;

  @override
  void dispose() {
    _marketUrlCtrl.dispose();
    _clipboardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCtrl = context.watch<ThemeModeController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '应用配色方案',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Material Design 3 预设，支持动态取色',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...LegadoColorPresets.all.map((info) {
          final selected = themeCtrl.preset == info.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: info.preview,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        color: theme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
              ),
              title: Text(info.label),
              subtitle: Text(
                info.description,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: selected
                  ? Icon(
                      Icons.radio_button_checked,
                      color: theme.colorScheme.primary,
                    )
                  : const Icon(Icons.radio_button_off, size: 20),
              onTap: () => themeCtrl.setPreset(info.id),
            ),
          );
        }),
        const SizedBox(height: 16),
        const ThemeColorEditor(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _exportTheme(themeCtrl),
              icon: const Icon(Icons.upload_file),
              label: const Text('导出'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showImportDialog(themeCtrl),
              icon: const Icon(Icons.download),
              label: const Text('导入'),
            ),
            OutlinedButton.icon(
              onPressed: _loadingMarket
                  ? null
                  : () => _showMarketDialog(themeCtrl),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('主题市场'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '阅读主题预设',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...ReaderTheme.themes.entries.map((entry) {
          final name = entry.key;
          final rt = entry.value;
          final labels = {
            'paper': '米黄',
            'white': '纯白',
            'dark': '暗黑',
            'green': '护眼绿',
          };
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rt.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
              title: Text(labels[name] ?? name),
              subtitle: Text(
                '背景 #${rt.background.toARGB32().toRadixString(16).substring(2)}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.menu_book_outlined, size: 18),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(
          '阅读主题在阅读器设置中切换；明暗模式请在「我的 → 主题模式」调整',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _exportTheme(ThemeModeController ctrl) {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(ctrl.exportConfig());
    unawaited(context.read<ClipboardPort>().copyText(json));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('主题配置已复制到剪贴板')));
  }

  Future<void> _showImportDialog(ThemeModeController ctrl) async {
    _clipboardCtrl.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入主题 JSON'),
        content: TextField(
          controller: _clipboardCtrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '粘贴主题 JSON…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final text = await context.read<ClipboardPort>().pasteText();
              if (text != null) {
                _clipboardCtrl.text = text;
              }
            },
            child: const Text('从剪贴板粘贴'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('应用'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _applyJson(ctrl, _clipboardCtrl.text);
  }

  Future<void> _showMarketDialog(ThemeModeController ctrl) async {
    _marketUrlCtrl.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题市场'),
        content: TextField(
          controller: _marketUrlCtrl,
          decoration: const InputDecoration(
            labelText: '主题 JSON URL',
            hintText: 'https://example.com/theme.json',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('加载'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loadingMarket = true);
    try {
      final config = await _importService.fetchFromUrl(
        _marketUrlCtrl.text,
        fetchPort: context.read<PublicTextFetchPort>(),
      );
      await _importService.applyTo(ctrl, config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('主题已从 URL 加载')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMarket = false);
    }
  }

  Future<void> _applyJson(ThemeModeController ctrl, String raw) async {
    try {
      final config = _importService.parseJson(raw);
      await _importService.applyTo(ctrl, config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('主题已导入')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }
}
