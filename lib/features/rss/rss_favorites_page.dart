import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/rss/rss_notifier.dart';
import '../../application/rss/rss_controller.dart';
import '../../domain/ports/application_http_request_port.dart';
import '../../domain/rss/rss_article.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../../application/rss/rss_star_prefs_port.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/remote_binary_image.dart';
import 'rss_read_page.dart';

/// RSS 收藏列表 — 对齐 Jingshiro RssFavorites / RssStar
class RssFavoritesPage extends StatelessWidget {
  const RssFavoritesPage({super.key, this.controller});

  final RssSourceController? controller;

  @override
  Widget build(BuildContext context) {
    final body = const _RssFavoritesPageBody();
    final sourceController =
        controller ?? _parentController(context) ?? RssSourceController();
    return riverpod.ProviderScope(
      overrides: [
        rssSourceControllerProvider.overrideWithValue(sourceController),
      ],
      child: body,
    );
  }

  RssSourceController? _parentController(BuildContext context) {
    try {
      return riverpod.ProviderScope.containerOf(
        context,
        listen: false,
      ).read(rssSourceControllerProvider);
    } catch (_) {
      return null;
    }
  }
}

class _RssFavoritesPageBody extends riverpod.ConsumerStatefulWidget {
  const _RssFavoritesPageBody();

  @override
  riverpod.ConsumerState<_RssFavoritesPageBody> createState() =>
      _RssFavoritesPageBodyState();
}

class _RssFavoritesPageBodyState
    extends riverpod.ConsumerState<_RssFavoritesPageBody> {
  List<RssArticle> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final port = context.read<RssStarPrefsPort?>();
    final items = port == null ? <RssArticle>[] : await port.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  RssSource? _findSource(String origin) {
    try {
      return ref
          .read(rssNotifierProvider)
          .sources
          .firstWhere((s) => s.sourceUrl == origin);
    } catch (_) {
      return null;
    }
  }

  Future<void> _open(RssArticle a) async {
    final source =
        _findSource(a.origin) ??
        RssSource(sourceUrl: a.origin, sourceName: a.origin);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RssReadPage(source: source, article: a),
      ),
    );
    await _load();
  }

  Future<void> _unstar(RssArticle a) async {
    await context.read<RssStarPrefsPort?>()?.remove(a.origin, a.link);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(rssNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.star_outline,
              title: '暂无收藏',
              subtitle: '在文章列表点星标即可收藏',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final a = _items[i];
                  return ListTile(
                    leading: a.image != null && a.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: RemoteBinaryImage(
                              url: a.image!,
                              policy: ApplicationHttpPolicy.localNetwork,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.star),
                            ),
                          )
                        : const Icon(Icons.star, color: Colors.amber),
                    title: Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      a.origin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: '取消收藏',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _unstar(a),
                    ),
                    onTap: () => _open(a),
                  );
                },
              ),
            ),
    );
  }
}
