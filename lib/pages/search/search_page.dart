import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../services/search_history.dart';
import '../../widgets/book_list_tile.dart';
import '../book/book_info_page.dart';

/// 搜索页面 — 按书源分组 + 搜索历史
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await SearchHistory.load();
    if (mounted) setState(() => _history = list);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _search(String keyword) {
    final q = keyword.trim();
    if (q.isEmpty) return;
    SearchHistory.add(q);
    _loadHistory();
    context.read<SourceProvider>().searchAll(q);
  }

  Widget _buildHistoryBar() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '搜索历史',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await SearchHistory.clear();
                  _loadHistory();
                },
                child: const Text('清空', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final item = _history[i];
                return InputChip(
                  label: Text(item, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _searchController.text = item;
                    _search(item);
                  },
                  onDeleted: () async {
                    await SearchHistory.remove(item);
                    _loadHistory();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 根据书源 URL 获取书源名称
  String _sourceName(SourceProvider provider, String sourceUrl) {
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('多分组/书源（待实现）')));
                  break;
                case 'all_sources':
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('全部书源（待实现）')));
                  break;
                case 'source_tags':
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('书源标签（待实现）')));
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
      body: Column(
        children: [
          _buildHistoryBar(),
          Expanded(
            child: Consumer<SourceProvider>(
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
                  Text(
                    '请耐心等待',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                    Text(
                      provider.statusMessage,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('试试其他关键词', style: TextStyle(color: Colors.grey[500])),
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
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('输入关键词搜索', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text(
                    '从所有已启用的书源中查找',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // ── 按书源分组展示 ──
          final groups = provider.searchResults.entries.toList()
            ..sort((a, b) => _sourceName(provider, a.key).compareTo(_sourceName(provider, b.key)));

          final totalCount = groups.fold<int>(0, (s, e) => s + e.value.length);
          final sourceCount = groups.length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final entry = groups[index];
                    final name = _sourceName(provider, entry.key);
                    return ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        '$name (${entry.value.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: entry.value
                          .map(
                            (book) => BookListTile(
                              book: book,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookInfoPage(book: book),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}
