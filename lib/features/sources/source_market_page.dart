import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../../application/source_management/source_notifier.dart';
import '../../application/source_market/source_market_mapper.dart';
import '../../application/source_market/source_market_port.dart';

/// 书源市场 - 内置推荐书源，一键导入
class SourceMarketPage extends StatefulWidget {
  const SourceMarketPage({super.key});

  @override
  State<SourceMarketPage> createState() => _SourceMarketPageState();
}

class _SourceMarketPageState extends State<SourceMarketPage> {
  late Future<Map<String, List<BookSource>>> _marketFuture;

  @override
  void initState() {
    super.initState();
    _marketFuture = _loadMarket();
  }

  Future<Map<String, List<BookSource>>> _loadMarket() async {
    final sources = await context.read<SourceMarketPort>().loadSources();
    return SourceMarketMapper.fromSources(sources);
  }

  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final notifier = ref.read(sourceNotifierProvider.notifier);
        return Scaffold(
          appBar: AppBar(
            title: const Text('书源市场'),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('全部导入'),
                onPressed: () async {
                  final market = await _marketFuture;
                  if (context.mounted) {
                    await _importAll(context, market, notifier);
                  }
                },
              ),
            ],
          ),
          body: FutureBuilder<Map<String, List<BookSource>>>(
            future: _marketFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('加载书源失败: ${snapshot.error}'));
              }
              final market = snapshot.data ?? {};
              return ListView(
                padding: const EdgeInsets.all(12),
                children: market.entries.map((entry) {
                  return _CategoryGroup(
                    category: entry.key,
                    sources: entry.value,
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _importAll(
    BuildContext context,
    Map<String, List<BookSource>> market,
    SourceNotifier notifier,
  ) async {
    final sources = [for (final entry in market.entries) ...entry.value];
    await notifier.importParsedSources(sources);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已导入所有书源')));
    Navigator.pop(context);
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<BookSource> sources;

  const _CategoryGroup({required this.category, required this.sources});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...sources.map((source) => _SourceMarketTile(source: source)),
      ],
    );
  }
}

class _SourceMarketTile extends riverpod.ConsumerWidget {
  final BookSource source;
  const _SourceMarketTile({required this.source});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final sources = ref.watch(
      sourceNotifierProvider.select((state) => state.sources),
    );
    final exists = sources.any((s) => s.bookSourceUrl == source.bookSourceUrl);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.rss_feed,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          source.bookSourceName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          source.bookSourceUrl,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: exists
            ? const Icon(Icons.check, color: Colors.green)
            : FilledButton.tonal(
                onPressed: () async {
                  await ref
                      .read(sourceNotifierProvider.notifier)
                      .addSource(source);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已添加 ${source.bookSourceName}')),
                  );
                },
                child: const Text('添加'),
              ),
      ),
    );
  }
}
