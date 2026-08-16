import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/reader/reader_font_port.dart';
import '../../application/rss/rss_login_port.dart';
import '../../application/rss/rss_notifier.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/legado_refresh_indicator.dart';
import '../../features/my/read_record_page.dart';
import '../sources/rule_sub_page.dart';
import '../../features/sources/source_login_page.dart';
import 'rss_articles_page.dart';
import 'rss_favorites_page.dart';
import 'rss_source_edit_page.dart';
import 'rss_source_manage_page.dart';
import 'widgets/rss_source_tile.dart';

/// 订阅 Tab — 对齐 Jingshiro [RssFragment] / `fragment_rss.xml` + `menu/main_rss.xml`
class RssTabPage extends StatefulWidget {
  const RssTabPage({super.key});

  @override
  State<RssTabPage> createState() => RssTabPageState();
}

class RssTabPageState extends State<RssTabPage> {
  @override
  Widget build(BuildContext context) {
    return const _RssTabPageBody();
  }
}

class _RssTabPageBody extends riverpod.ConsumerStatefulWidget {
  const _RssTabPageBody();

  @override
  riverpod.ConsumerState<_RssTabPageBody> createState() =>
      _RssTabPageBodyState();
}

class _RssTabPageBodyState extends riverpod.ConsumerState<_RssTabPageBody> {
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
      MaterialPageRoute(builder: (_) => RssArticlesPage(source: source)),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReadRecordPage()),
    );
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RssFavoritesPage()),
    );
  }

  void _openManage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RssSourceManagePage()),
    );
  }

  void _showSourceMenu(RssSource source, Offset anchor) {
    final provider = ref.read(rssNotifierProvider.notifier);
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
              builder: (_) => RssSourceEditPage(source: source),
            ),
          );
        case 'top':
          await provider.topSource(source);
        case 'login':
          await SourceLoginPage.open(
            context,
            context.read<RssLoginPort>().bookSourceForRss(source),
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

  /// TitleBar 内嵌搜索 — 对齐 `view_search.xml` + `bg_searchview`（主色上 10% 透明底）
  Widget _buildSearchField(ColorScheme scheme) {
    final onBar = scheme.onPrimary;
    final font = context.read<ReaderFontPort>();
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          color: onBar,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: font.platformSansFamily(),
          fontFamilyFallback: font.cjkFallbackFamilies(),
        ),
        cursorColor: onBar,
        decoration: InputDecoration(
          hintText: '订阅',
          hintStyle: TextStyle(
            color: onBar.withValues(alpha: 0.72),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: font.platformSansFamily(),
            fontFamilyFallback: font.cjkFallbackFamilies(),
          ),
          isDense: true,
          filled: true,
          fillColor: onBar.withValues(alpha: 0.10),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: onBar.withValues(alpha: 0.85),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: onBar.withValues(alpha: 0.85),
                  ),
                  onPressed: _clearSearch,
                  visualDensity: VisualDensity.compact,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.22),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ref.watch(rssNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: LegadoTokens.spacingSm,
        title: _buildSearchField(scheme),
        // 对齐 main_rss.xml：历史 / 收藏 / 分组 / 设置 始终显示在顶栏
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '阅读记录',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: '收藏',
            onPressed: _openFavorites,
          ),
          riverpod.Consumer(
            builder: (context, ref, _) {
              final groups = ref
                  .read(rssNotifierProvider.notifier)
                  .enabledGroups();
              return IconButton(
                icon: const Icon(Icons.hub_outlined),
                tooltip: '分组',
                onPressed: () {
                  if (groups.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('暂无分组')));
                  } else {
                    _showGroupPicker(groups);
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '订阅源管理',
            onPressed: _openManage,
          ),
        ],
      ),
      body: riverpod.Consumer(
        builder: (context, ref, _) {
          final sources = ref
              .read(rssNotifierProvider.notifier)
              .enabledSources(searchKey: _searchController.text);
          return ScrollConfiguration(
            behavior: LegadoScrollBehavior(overscrollColor: scheme.primary),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                // item_rss + GridLayoutManager spanCount=4
                crossAxisCount: 4,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: 0.78,
              ),
              itemCount: sources.length + 1,
              itemBuilder: (_, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: RssSourceTile(
                      name: '规则订阅',
                      icon: Icons.menu_book_rounded,
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
                        final box =
                            tileContext.findRenderObject() as RenderBox?;
                        final offset =
                            box?.localToGlobal(Offset.zero) ?? Offset.zero;
                        _showSourceMenu(source, offset);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
