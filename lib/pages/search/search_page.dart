import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/library_provider.dart';
import '../reader/reader_page.dart';

/// 搜索页面 - 扁平列表（仿 Legado 风格）
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _search(String keyword) {
    if (keyword.trim().isEmpty) return;
    context.read<LibraryProvider>().searchAll(keyword.trim());
  }

  /// 根据书源 URL 获取书源名称
  String _sourceName(LibraryProvider provider, String sourceUrl) {
    for (final s in provider.sources) {
      if (s.bookSourceUrl == sourceUrl) {
        return s.bookSourceName;
      }
    }
    return Uri.tryParse(sourceUrl)?.host ?? sourceUrl;
  }

  /// 精准搜索对话框
  void _showPreciseSearchDialog() {
    final keywordCtl = TextEditingController(text: _searchController.text);
    final authorCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('精准搜索'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keywordCtl,
              decoration: const InputDecoration(
                labelText: '书名',
                hintText: '输入书名',
                prefixIcon: Icon(Icons.book, size: 20),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorCtl,
              decoration: const InputDecoration(
                labelText: '作者（可选）',
                hintText: '输入作者名筛选',
                prefixIcon: Icon(Icons.person, size: 20),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final keyword = keywordCtl.text.trim();
              final author = authorCtl.text.trim();
              if (keyword.isEmpty) return;
              // 传参搜索，后续可扩展 author 过滤
              _search('$keyword ${author.isNotEmpty ? author : ''}'.trim());
            },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入书名、作者搜索...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _search(_searchController.text),
            ),
          ),
          onSubmitted: _search,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'sources':
                  Navigator.pushNamed(context, '/sources');
                  break;
                case 'precise_search':
                  _showPreciseSearchDialog();
                  break;
                case 'multi_group':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('多分组/书源（待实现）')),
                  );
                  break;
                case 'all_sources':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('全部书源（待实现）')),
                  );
                  break;
                case 'source_tags':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('书源标签（待实现）')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'precise_search',
                child: ListTile(
                  leading: Icon(Icons.tune, size: 20),
                  title: Text('精准搜索', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sources',
                child: ListTile(
                  leading: Icon(Icons.rss_feed, size: 20),
                  title: Text('书源管理', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'multi_group',
                child: ListTile(
                  leading: Icon(Icons.widgets, size: 20),
                  title: Text('多分组/书源', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'all_sources',
                child: ListTile(
                  leading: Icon(Icons.dns, size: 20),
                  title: Text('全部书源', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'source_tags',
                child: ListTile(
                  leading: Icon(Icons.label, size: 20),
                  title: Text('书源标签', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在搜索多个书源...'),
                  SizedBox(height: 8),
                  Text('请耐心等待', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          if (provider.searchResults.isEmpty) {
            if (provider.statusMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(provider.statusMessage,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('试试其他关键词',
                        style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('书源可能已失效，请导入社区书源'),
                      onPressed: () => Navigator.pushNamed(context, '/sources'),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search,
                        size: 48, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('输入关键词搜索',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('从所有已启用的书源中查找',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            );
          }

          // ── 构建扁平搜索结果列表 ──
          // 收集所有结果并记录来源名称
          final flatResults = <_SearchResultItem>[];
          provider.searchResults.forEach((sourceUrl, books) {
            final name = _sourceName(provider, sourceUrl);
            for (final book in books) {
              flatResults.add(_SearchResultItem(book: book, sourceName: name));
            }
          });

          // 总结果数统计
          final totalCount = flatResults.length;
          final sourceCount = provider.searchResults.length;

          return Column(
            children: [
              // 统计栏
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Text(
                  '共 $totalCount 本书 · $sourceCount 个书源',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // 结果列表
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: flatResults.length,
                  itemBuilder: (context, index) {
                    final item = flatResults[index];
                    return _SearchResultTile(
                      book: item.book,
                      sourceName: item.sourceName,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 扁平搜索结果条目
class _SearchResultItem {
  final Book book;
  final String sourceName;

  const _SearchResultItem({required this.book, required this.sourceName});
}

/// 单个搜索结果的展示 Tile（仿 Legado 风格）
class _SearchResultTile extends StatelessWidget {
  final Book book;
  final String sourceName;

  const _SearchResultTile({
    required this.book,
    required this.sourceName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 提取书源名（去除图标 emoji）
    String cleanSourceName = sourceName;
    final emojiRegex = RegExp(r'^[\u{1F000}-\u{1FFFF}\u{2000}-\u{2FFF}]\s*',
        unicode: true);
    cleanSourceName =
        cleanSourceName.replaceAll(emojiRegex, '').trim();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: book.coverUrl.isNotEmpty
              ? Image.network(
                  book.coverUrl,
                  width: 40,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverPlaceholder(theme),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return _coverPlaceholder(theme);
                  },
                )
              : _coverPlaceholder(theme),
        ),
      ),
      title: Text(
        book.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (book.author.isNotEmpty) ...[
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
          ],
          // 书源标签（小圆角 chip）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              cleanSourceName,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(book: book),
          ),
        );
      },
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(Icons.menu_book,
          size: 20, color: theme.colorScheme.primary),
    );
  }
}
