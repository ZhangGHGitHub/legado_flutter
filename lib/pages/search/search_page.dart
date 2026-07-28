import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_source.dart';
import '../../providers/source_provider.dart';
import '../../services/search_history.dart';
import '../../widgets/book_list_tile.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';

/// 搜索范围模式
enum _ScopeMode { all, groups, sources }

/// 搜索页面 — 按书源分组 + 精准搜索 + 搜索范围
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialRestrictSourceUrls});

  /// 非空时锁定为「按书源」并预选（书源编辑页「搜索」入口，对齐单源 scope）
  final Set<String>? initialRestrictSourceUrls;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<String> _history = [];

  /// 空 = 全部已启用；非空 = 限定书源 URL
  Set<String> _scopeSourceUrls = {};
  _ScopeMode _scopeMode = _ScopeMode.all;
  Set<String> _selectedGroups = {};

  @override
  void initState() {
    super.initState();
    final locked = widget.initialRestrictSourceUrls;
    if (locked != null && locked.isNotEmpty) {
      _scopeMode = _ScopeMode.sources;
      _scopeSourceUrls = Set<String>.from(locked);
    }
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

  Set<String>? _resolvedScopeUrls(SourceProvider provider) {
    if (_scopeMode == _ScopeMode.all || _scopeSourceUrls.isEmpty) {
      if (_scopeMode == _ScopeMode.groups && _selectedGroups.isNotEmpty) {
        return provider.sources
            .where(
              (s) =>
                  s.enabled &&
                  _selectedGroups.contains(
                    s.bookSourceGroup.isEmpty ? '未分组' : s.bookSourceGroup,
                  ),
            )
            .map((s) => s.bookSourceUrl)
            .toSet();
      }
      if (_scopeMode == _ScopeMode.sources && _scopeSourceUrls.isNotEmpty) {
        return _scopeSourceUrls;
      }
      return null;
    }
    return _scopeSourceUrls;
  }

  String _scopeSummary(SourceProvider provider) {
    switch (_scopeMode) {
      case _ScopeMode.all:
        return '全部已启用书源';
      case _ScopeMode.groups:
        if (_selectedGroups.isEmpty) return '全部已启用书源';
        return '分组: ${_selectedGroups.join('、')}';
      case _ScopeMode.sources:
        if (_scopeSourceUrls.isEmpty) return '全部已启用书源';
        return '已选 ${_scopeSourceUrls.length} 个书源';
    }
  }

  void _search(String keyword, {String? author, bool preciseName = false}) {
    final q = keyword.trim();
    if (q.isEmpty) return;
    SearchHistory.add(q);
    _loadHistory();
    final provider = context.read<SourceProvider>();
    provider.searchAll(
      q,
      author: author,
      preciseName: preciseName,
      restrictSourceUrls: _resolvedScopeUrls(provider),
    );
  }

  Widget _buildHistoryBar() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
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

  String _sourceName(SourceProvider provider, String sourceUrl) {
    for (final s in provider.sources) {
      if (s.bookSourceUrl == sourceUrl) {
        return s.bookSourceName;
      }
    }
    return Uri.tryParse(sourceUrl)?.host ?? sourceUrl;
  }

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
                hintText: '书名须包含关键词',
                prefixIcon: Icon(Icons.book, size: 20),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorCtl,
              decoration: const InputDecoration(
                labelText: '作者（可选）',
                hintText: '按作者筛选结果',
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
              _searchController.text = keyword;
              _search(keyword, author: author, preciseName: true);
            },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScopeDialog() async {
    final provider = context.read<SourceProvider>();
    final enabled = provider.sources.where((s) => s.enabled).toList();
    final groups = <String>{
      for (final s in enabled)
        s.bookSourceGroup.isEmpty ? '未分组' : s.bookSourceGroup,
    }.toList()..sort();

    var mode = _scopeMode;
    var selectedGroups = Set<String>.from(_selectedGroups);
    var selectedUrls = Set<String>.from(_scopeSourceUrls);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('搜索范围'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioGroup<_ScopeMode>(
                      groupValue: mode,
                      onChanged: (v) {
                        if (v != null) setLocal(() => mode = v);
                      },
                      child: Column(
                        children: [
                          RadioListTile<_ScopeMode>(
                            dense: true,
                            title: const Text('全部已启用书源'),
                            value: _ScopeMode.all,
                          ),
                          RadioListTile<_ScopeMode>(
                            dense: true,
                            title: const Text('按书源分组'),
                            value: _ScopeMode.groups,
                          ),
                          RadioListTile<_ScopeMode>(
                            dense: true,
                            title: const Text('自选书源'),
                            value: _ScopeMode.sources,
                          ),
                        ],
                      ),
                    ),
                    if (mode == _ScopeMode.groups) ...[
                      const Divider(),
                      ...groups.map(
                        (g) => CheckboxListTile(
                          dense: true,
                          title: Text(g),
                          value: selectedGroups.contains(g),
                          onChanged: (v) => setLocal(() {
                            if (v == true) {
                              selectedGroups.add(g);
                            } else {
                              selectedGroups.remove(g);
                            }
                          }),
                        ),
                      ),
                    ],
                    if (mode == _ScopeMode.sources) ...[
                      const Divider(),
                      ...enabled.map(
                        (BookSource s) => CheckboxListTile(
                          dense: true,
                          title: Text(s.bookSourceName),
                          subtitle: Text(
                            s.bookSourceGroup.isEmpty
                                ? '未分组'
                                : s.bookSourceGroup,
                            style: const TextStyle(fontSize: 11),
                          ),
                          value: selectedUrls.contains(s.bookSourceUrl),
                          onChanged: (v) => setLocal(() {
                            if (v == true) {
                              selectedUrls.add(s.bookSourceUrl);
                            } else {
                              selectedUrls.remove(s.bookSourceUrl);
                            }
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && mounted) {
      setState(() {
        _scopeMode = mode;
        _selectedGroups = selectedGroups;
        _scopeSourceUrls = selectedUrls;
      });
    }
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
            offset: legadoAppBarPopupOffset(context),
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'sources':
                  Navigator.pushNamed(context, '/sources');
                  break;
                case 'precise_search':
                  _showPreciseSearchDialog();
                  break;
                case 'scope':
                  _showScopeDialog();
                  break;
                case 'all_sources':
                  setState(() {
                    _scopeMode = _ScopeMode.all;
                    _scopeSourceUrls = {};
                    _selectedGroups = {};
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已切换为全部已启用书源')));
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
                value: 'scope',
                child: ListTile(
                  leading: Icon(Icons.filter_list, size: 20),
                  title: Text('搜索范围', style: TextStyle(fontSize: 14)),
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
                value: 'sources',
                child: ListTile(
                  leading: Icon(Icons.rss_feed, size: 20),
                  title: Text('书源管理', style: TextStyle(fontSize: 14)),
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
          Consumer<SourceProvider>(
            builder: (context, provider, _) {
              return Material(
                color: theme.colorScheme.surfaceContainerLow,
                child: InkWell(
                  onTap: _showScopeDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '范围：${_scopeSummary(provider)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<SourceProvider>(
              builder: (context, provider, _) {
                final hasResults = provider.searchResults.isNotEmpty;

                if (provider.isLoading && !hasResults) {
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

                if (!hasResults) {
                  if (provider.statusMessage.isNotEmpty &&
                      !provider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.statusMessage,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '试试其他关键词或调整搜索范围',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: const Text('书源可能已失效，请导入社区书源'),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/sources'),
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
                          child: Icon(
                            Icons.search,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '输入关键词搜索',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '从选定的书源中查找',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final groups = provider.searchResults.entries.toList()
                  ..sort(
                    (a, b) => _sourceName(
                      provider,
                      a.key,
                    ).compareTo(_sourceName(provider, b.key)),
                  );

                final totalCount = groups.fold<int>(
                  0,
                  (s, e) => s + e.value.length,
                );
                final sourceCount = groups.length;

                return Column(
                  children: [
                    if (provider.isLoading)
                      const LinearProgressIndicator(minHeight: 2),
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
                                        builder: (_) =>
                                            BookInfoPage(book: book),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    // 底栏统计（对齐 Jingshiro）
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        border: Border(
                          top: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        provider.isLoading
                            ? '搜索中… 已找到 $totalCount 本 · $sourceCount 个书源'
                            : '共 $totalCount 本 · $sourceCount 个书源',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
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
