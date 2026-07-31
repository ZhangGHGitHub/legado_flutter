import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/rss/rss_sort_urls_port.dart';
import '../../application/rss/rss_login_port.dart';
import '../../domain/ports/application_http_request_port.dart';
import '../../domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../../application/rss/rss_read_state_port.dart';
import '../../application/rss/rss_star_prefs_port.dart';
import '../../domain/ports/rss_port.dart';
import '../../widgets/remote_binary_image.dart';
import '../../features/sources/source_login_page.dart';
import 'rss_read_page.dart';
import 'rss_source_edit_page.dart';

/// RSS 文章列表 — 对齐 Jingshiro RssSortActivity / RssArticlesFragment。
class RssArticlesPage extends StatefulWidget {
  const RssArticlesPage({super.key, required this.source, this.sortUrlsPort});

  final RssSource source;

  @visibleForTesting
  final RssSortUrlsPort? sortUrlsPort;

  @override
  State<RssArticlesPage> createState() => _RssArticlesPageState();
}

class _RssArticlesPageState extends State<RssArticlesPage>
    with TickerProviderStateMixin {
  List<(String name, String url)> _sorts = const [];
  TabController? _tabController;
  var _resolving = true;
  String? _resolveError;
  late final RssSortUrlsPort _sortUrlsPort;

  RssSource get source => widget.source;

  @override
  void initState() {
    super.initState();
    _sortUrlsPort = widget.sortUrlsPort ?? context.read<RssSortUrlsPort>();
    _resolveSorts();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _resolveSorts() async {
    setState(() {
      _resolving = true;
      _resolveError = null;
    });
    try {
      final sorts = await _sortUrlsPort.resolve(source);
      if (!mounted) return;
      _tabController?.dispose();
      _tabController = sorts.length > 1
          ? TabController(length: sorts.length, vsync: this)
          : null;
      setState(() {
        _sorts = sorts;
        _resolving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolveError = e.toString();
        _resolving = false;
        _sorts = [('', source.sourceUrl)];
      });
    }
  }

  Future<void> _clearSortCacheAndReload() async {
    await _sortUrlsPort.clearCache(source);
    await _resolveSorts();
  }

  @override
  Widget build(BuildContext context) {
    final hasTabs = _sorts.length > 1 && _tabController != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(source.sourceName),
        bottom: hasTabs
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  for (final s in _sorts) Tab(text: s.$1.isEmpty ? '全部' : s.$1),
                ],
              )
            : null,
        actions: [
          if (source.loginUrl != null && source.loginUrl!.trim().isNotEmpty)
            IconButton(
              tooltip: '登录',
              icon: const Icon(Icons.login),
              onPressed: () => SourceLoginPage.open(
                context,
                context.read<RssLoginPort>().bookSourceForRss(source),
              ),
            ),
          IconButton(
            tooltip: '编辑源',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RssSourceEditPage(source: source),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '刷新分类',
            icon: const Icon(Icons.cached_outlined),
            onPressed: _resolving ? null : _clearSortCacheAndReload,
          ),
        ],
      ),
      body: _buildBody(hasTabs),
    );
  }

  Widget _buildBody(bool hasTabs) {
    if (_resolving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_resolveError != null && _sorts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_resolveError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _resolveSorts, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (hasTabs) {
      return TabBarView(
        controller: _tabController,
        children: [
          for (final s in _sorts)
            _RssArticlesList(
              source: source,
              sortName: s.$1.isEmpty ? source.sourceName : s.$1,
              sortUrl: s.$2,
            ),
        ],
      );
    }
    final s = _sorts.isNotEmpty ? _sorts.first : ('', source.sourceUrl);
    return _RssArticlesList(
      source: source,
      sortName: s.$1.isEmpty ? source.sourceName : s.$1,
      sortUrl: s.$2,
    );
  }
}

class _RssArticlesList extends StatefulWidget {
  const _RssArticlesList({
    required this.source,
    required this.sortName,
    required this.sortUrl,
  });

  final RssSource source;
  final String sortName;
  final String sortUrl;

  @override
  State<_RssArticlesList> createState() => _RssArticlesListState();
}

class _RssArticlesListState extends State<_RssArticlesList>
    with AutomaticKeepAliveClientMixin {
  final _articles = <RssArticle>[];
  final _readLinks = <String>{};
  final _starred = <String>{};
  var _loading = true;
  var _loadingMore = false;
  String? _error;
  String? _nextUrl;
  var _page = 1;
  late final RssPort _rssPort;

  RssSource get source => widget.source;

  @override
  bool get wantKeepAlive => true;

  String _starKey(RssArticle a) => '${a.origin}|${a.link}';

  @override
  void initState() {
    super.initState();
    _rssPort = context.read<RssPort>();
    _loadMeta();
    _refresh();
  }

  Future<void> _loadMeta() async {
    final readState = context.read<RssReadStatePort>();
    final starPrefs = context.read<RssStarPrefsPort>();
    final list = await readState.read(source.sourceUrl);
    final stars = await starPrefs.loadAll();
    if (!mounted) return;
    setState(() {
      _readLinks
        ..clear()
        ..addAll(list);
      _starred
        ..clear()
        ..addAll(
          stars.where((a) => a.origin == source.sourceUrl).map(_starKey),
        );
    });
  }

  Future<void> _markRead(RssArticle a) async {
    _readLinks.add(a.link);
    await context.read<RssReadStatePort>().write(source.sourceUrl, _readLinks);
    if (mounted) setState(() {});
  }

  Future<void> _toggleStar(RssArticle a) async {
    final starred = await context.read<RssStarPrefsPort>().toggle(a);
    if (!mounted) return;
    setState(() {
      if (starred) {
        _starred.add(_starKey(a));
      } else {
        _starred.remove(_starKey(a));
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(starred ? '已收藏' : '已取消收藏')));
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final r = await _rssPort.getArticles(
        source: source,
        sortName: widget.sortName,
        sortUrl: widget.sortUrl,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _articles
          ..clear()
          ..addAll(r.articles);
        _nextUrl = r.nextUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextUrl == null || _nextUrl!.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final r = await _rssPort.getArticles(
        source: source,
        sortName: widget.sortName,
        sortUrl: _nextUrl!,
        page: ++_page,
      );
      if (!mounted) return;
      setState(() {
        _articles.addAll(r.articles);
        _nextUrl = r.nextUrl;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载更多失败: $e')));
    }
  }

  Future<void> _openArticle(RssArticle article) async {
    await _markRead(article);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RssReadPage(source: source, article: article),
      ),
    );
    await _loadMeta();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _refresh, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('暂无文章')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          itemCount: _articles.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            if (i >= _articles.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final a = _articles[i];
            final read = _readLinks.contains(a.link);
            final starred = _starred.contains(_starKey(a));
            return ListTile(
              leading: a.image != null && a.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: RemoteBinaryImage(
                        url: a.image!,
                        policy: ApplicationHttpPolicy.localNetwork,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.article_outlined, size: 40),
                      ),
                    )
                  : const Icon(Icons.article_outlined, size: 40),
              title: Text(
                a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: read ? FontWeight.normal : FontWeight.w600,
                  color: read
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              subtitle: Text(
                [
                  if (a.pubDate != null && a.pubDate!.isNotEmpty) a.pubDate!,
                  if (a.description != null && a.description!.isNotEmpty)
                    a.description!.replaceAll(RegExp(r'<[^>]+>'), ' ').trim(),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: starred ? '取消收藏' : '收藏',
                icon: Icon(
                  starred ? Icons.star : Icons.star_border,
                  color: starred ? Colors.amber : null,
                ),
                onPressed: () => _toggleStar(a),
              ),
              onTap: () => _openArticle(a),
            );
          },
        ),
      ),
    );
  }
}
