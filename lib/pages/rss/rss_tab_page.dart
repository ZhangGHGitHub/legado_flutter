import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/rss_source.dart';
import '../../providers/rss_provider.dart';
import '../config/feature_placeholder_page.dart';
import '../my/read_record_page.dart';
import '../rule_sub/rule_sub_page.dart';
import 'rss_articles_page.dart';
import 'rss_source_manage_page.dart';
import 'widgets/rss_source_tile.dart';

/// 订阅 Tab — 对齐 Jingshiro [RssFragment](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/rss/RssFragment.kt)
class RssTabPage extends StatefulWidget {
  const RssTabPage({super.key});

  @override
  State<RssTabPage> createState() => RssTabPageState();
}

class RssTabPageState extends State<RssTabPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyGroupFilter(String group) {
    _searchController.text = 'group:$group';
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _openRuleSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RuleSubPage()),
    );
  }

  void _openRssSource(RssSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RssArticlesPage(source: source),
      ),
    );
  }

  void _showSourceMenu(RssSource source, Offset anchor) {
    final provider = context.read<RssProvider>();
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        anchor.dx,
        anchor.dy,
        anchor.dx,
        anchor.dy,
      ),
      items: [
        const PopupMenuItem(value: 'edit', child: Text('编辑')),
        const PopupMenuItem(value: 'top', child: Text('置顶')),
        if (source.loginUrl != null && source.loginUrl!.isNotEmpty)
          const PopupMenuItem(value: 'login', child: Text('登录')),
        const PopupMenuItem(value: 'disable', child: Text('禁用源')),
        const PopupMenuItem(value: 'del', child: Text('删除')),
      ],
    ).then((action) async {
      if (action == null || !mounted) return;
      switch (action) {
        case 'edit':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeaturePlaceholderPage(
                title: '编辑订阅源',
                subtitle: source.sourceName,
                icon: Icons.edit_outlined,
              ),
            ),
          );
        case 'top':
          await provider.topSource(source);
        case 'login':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeaturePlaceholderPage(
                title: '登录',
                subtitle: source.sourceName,
                icon: Icons.login,
              ),
            ),
          );
        case 'disable':
          await provider.disableSource(source);
        case 'del':
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除'),
              content: Text('确定删除\n${source.sourceName}？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
          if (yes == true) await provider.deleteSource(source);
      }
    });
  }

  void _showGroupPicker(List<String> groups) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部分组'),
              leading: const Icon(Icons.clear_all),
              onTap: () {
                Navigator.pop(ctx);
                _clearSearch();
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(groups[i]),
                  leading: const Icon(Icons.folder_outlined),
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyGroupFilter(groups[i]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜索订阅',
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _clearSearch,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          Consumer<RssProvider>(
            builder: (context, provider, _) {
              final groups = provider.enabledGroups();
              return PopupMenuButton<String>(
                tooltip: '更多',
                onSelected: (value) {
                  switch (value) {
                    case 'history':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReadRecordPage(),
                        ),
                      );
                    case 'favorite':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeaturePlaceholderPage(
                            title: '收藏',
                            subtitle: 'RSS 收藏文章列表',
                            icon: Icons.star_outline,
                          ),
                        ),
                      );
                    case 'group':
                      if (groups.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('暂无分组')),
                        );
                      } else {
                        _showGroupPicker(groups);
                      }
                    case 'manage':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RssSourceManagePage(),
                        ),
                      );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('阅读记录'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'favorite',
                    child: ListTile(
                      leading: Icon(Icons.star_outline),
                      title: Text('收藏'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'group',
                    child: ListTile(
                      leading: Icon(Icons.folder_outlined),
                      title: Text('分组'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('订阅源管理'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<RssProvider>(
        builder: (context, provider, _) {
          final sources = provider.enabledSources(
            searchKey: _searchController.text,
          );
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 0.72,
            ),
            itemCount: sources.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: RssSourceTile(
                    name: '规则订阅',
                    icon: Icons.auto_stories,
                    onTap: _openRuleSubscription,
                  ),
                );
              }
              final source = sources[index - 1];
              return Builder(
                builder: (tileContext) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: RssSourceTile.fromSource(
                    source,
                    onTap: () => _openRssSource(source),
                    onLongPress: () {
                      final box = tileContext.findRenderObject() as RenderBox?;
                      final offset =
                          box?.localToGlobal(Offset.zero) ?? Offset.zero;
                      _showSourceMenu(source, offset);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
