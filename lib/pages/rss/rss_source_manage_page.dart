import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/rss_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/legado_list_tile.dart';
import '../config/feature_placeholder_page.dart';

/// 订阅源管理 — 对齐 RssSourceActivity（管理入口；编辑/规则后续接入）
class RssSourceManagePage extends StatelessWidget {
  const RssSourceManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '导入订阅源',
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: Consumer<RssProvider>(
        builder: (context, provider, _) {
          final sources = provider.sources;
          if (sources.isEmpty) {
            return EmptyState(
              icon: Icons.subscriptions_outlined,
              title: '暂无订阅源',
              subtitle: '点击右上角 + 粘贴 Legado RSS 源 JSON 导入',
              actionLabel: '导入订阅源',
              onAction: () => _showImportDialog(context),
            );
          }
          return ListView.separated(
            itemCount: sources.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = sources[i];
              return LegadoListTile(
                icon: Icons.rss_feed,
                title: s.sourceName,
                subtitle: s.enabled ? s.sourceUrl : '${s.sourceUrl}（已禁用）',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeaturePlaceholderPage(
                      title: '编辑订阅源',
                      subtitle: s.sourceName,
                      icon: Icons.edit_outlined,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入订阅源'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '粘贴 RSS 源 JSON 数组…',
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
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await context.read<RssProvider>().importSources(
          controller.text,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '导入成功' : '导入失败，请检查 JSON 格式'),
      ),
    );
  }
}
