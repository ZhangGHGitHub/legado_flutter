import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_source.dart';
import '../../providers/source_provider.dart';
import '../../services/book_source_service.dart';

/// 书源市场 - 内置推荐书源，一键导入
class SourceMarketPage extends StatelessWidget {
  const SourceMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final market = BookSourceService.sourceMarket();

    return Scaffold(
      appBar: AppBar(
        title: const Text('书源市场'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('全部导入'),
            onPressed: () => _importAll(context, market),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: market.entries.map((entry) {
          return _CategoryGroup(
            category: entry.key,
            sources: entry.value,
          );
        }).toList(),
      ),
    );
  }

  void _importAll(BuildContext context, Map<String, List<BookSource>> market) {
    final provider = context.read<SourceProvider>();
    for (final entry in market.entries) {
      for (final source in entry.value) {
        provider.addSource(source);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已导入所有书源')),
    );
    Navigator.pop(context);
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<BookSource> sources;

  const _CategoryGroup({
    required this.category,
    required this.sources,
  });

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

class _SourceMarketTile extends StatelessWidget {
  final BookSource source;
  const _SourceMarketTile({required this.source});

  @override
  Widget build(BuildContext context) {
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
        trailing: Consumer<SourceProvider>(
          builder: (context, provider, _) {
            final exists = provider.sources.any(
              (s) => s.bookSourceUrl == source.bookSourceUrl,
            );
            return exists
                ? const Icon(Icons.check, color: Colors.green)
                : FilledButton.tonal(
                    onPressed: () {
                      provider.addSource(source);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已添加 ${source.bookSourceName}')),
                      );
                    },
                    child: const Text('添加'),
                  );
          },
        ),
      ),
    );
  }
}
