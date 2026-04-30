import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/book_source.dart';
import '../../providers/source_provider.dart';
import '../../providers/book_provider.dart';
import 'source_editor_page.dart';
import 'source_market_page.dart';

/// 书源管理页面 + 本地导入入口
class SourcesPage extends StatelessWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('书源'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'import_json') {
                _importFromJsonFile(context);
              } else if (v == 'paste_json') {
                _showPasteDialog(context);
              } else if (v == 'import_url') {
                _showImportUrlDialog(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'import_json', child: ListTile(
                leading: Icon(Icons.file_open, size: 20),
                title: Text('从JSON文件导入'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'paste_json', child: ListTile(
                leading: Icon(Icons.content_paste, size: 20),
                title: Text('粘贴JSON代码'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'import_url', child: ListTile(
                leading: Icon(Icons.cloud_download, size: 20),
                title: Text('从URL导入'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: '书源市场',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourceMarketPage()),
            ),
          ),
        ],
      ),
      body: Consumer<SourceProvider>(
        builder: (context, provider, _) {
          final sources = provider.sources;

          if (sources.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // 快捷操作栏
              Container(
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.store, size: 18),
                        label: const Text('书源市场'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SourceMarketPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.file_open, size: 18),
                        label: const Text('导入TXT'),
                        onPressed: () => _importLocalBook(context),
                      ),
                    ),
                  ],
                ),
              ),
              // 书源列表
              Expanded(
                child: sources.isEmpty
                    ? Center(child: Text('暂无书源', style: TextStyle(color: Colors.grey[500])))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: sources.length,
                        separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          return _SourceTile(source: sources[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rss_feed, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('还没有书源', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('去书源市场一键导入，或从JSON文件导入',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('打开书源市场'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourceMarketPage()),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_open),
            label: const Text('从JSON文件导入'),
            onPressed: () => _importFromJsonFile(context),
          ),
        ],
      ),
    );
  }

  /// 从JSON文件导入书源
  Future<void> _importFromJsonFile(BuildContext context) async {
    final provider = context.read<SourceProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonText = await file.readAsString();
      await provider.importSources(jsonText);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 书源导入成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 粘贴JSON代码
  void _showPasteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('粘贴书源JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '粘贴 legado 书源 JSON 代码...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SourceProvider>().importSources(controller.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 书源导入成功')),
              );
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 从 URL 导入书源（从 Legado 社区仓库获取）
  void _showImportUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('从URL导入书源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '输入书源JSON的URL...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '示例：可从 Legado 社区获取书源仓库地址',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton.icon(
            icon: const Icon(Icons.cloud_download, size: 18),
            label: const Text('获取并导入'),
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              final provider = context.read<SourceProvider>();
              final success = await provider.importSourcesFromUrl(url);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  success
                      ? const SnackBar(content: Text('✅ 书源导入成功'))
                      : const SnackBar(content: Text('❌ 导入失败，请检查URL'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// 导入本地书籍
  void _importLocalBook(BuildContext context) {
    context.read<BookProvider>().importLocalBook();
  }
}

/// 单个书源码 Tile
class _SourceTile extends StatelessWidget {
  final BookSource source;
  const _SourceTile({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: source.enabled
            ? theme.colorScheme.primaryContainer
            : Colors.grey[200],
        radius: 18,
        child: Icon(
          Icons.rss_feed,
          size: 20,
          color: source.enabled ? theme.colorScheme.primary : Colors.grey,
        ),
      ),
      title: Text(
        source.bookSourceName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: source.enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        source.bookSourceGroup.isNotEmpty
            ? '${source.bookSourceGroup} | ${source.bookSourceUrl}'
            : source.bookSourceUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Switch(
        value: source.enabled,
        onChanged: (v) => context.read<SourceProvider>().toggleSource(
          source.bookSourceUrl, v,
        ),
      ),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除书源'),
            content: Text('确定删除「${source.bookSourceName}」？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<SourceProvider>().deleteSource(source.bookSourceUrl);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<SourceProvider>(),
              child: SourceEditorPage(source: source),
            ),
          ),
        );
      },
    );
  }
}
