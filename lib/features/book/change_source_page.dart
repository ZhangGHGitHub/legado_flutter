import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/domain/book/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_state.dart';

/// 换源页 — 按书名在启用书源中搜索，选中后更新来源并刷新目录
class ChangeSourcePage extends StatefulWidget {
  final Book book;

  const ChangeSourcePage({super.key, required this.book});

  @override
  State<ChangeSourcePage> createState() => _ChangeSourcePageState();
}

class _ChangeSourcePageState extends State<ChangeSourcePage> {
  bool _applying = false;
  String? _applyError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSearch());
  }

  Future<void> _startSearch() async {
    final name = widget.book.name.trim();
    if (name.isEmpty) return;
    final author = widget.book.author.trim();
    final provider = context.read<SourceProvider>();
    await provider.searchAll(
      name,
      author: author.isNotEmpty && author != '未知作者' ? author : null,
      preciseName: true,
    );
  }

  String _sourceName(SourceProvider provider, String sourceUrl) {
    for (final s in provider.sources) {
      if (s.bookSourceUrl == sourceUrl) return s.bookSourceName;
    }
    return Uri.tryParse(sourceUrl)?.host ?? sourceUrl;
  }

  String _latestLine(Book book) {
    final last = book.lastChapter?.trim();
    if (last != null && last.isNotEmpty) return last;
    final note = book.description.trim();
    if (note.isNotEmpty) return note;
    return '';
  }

  bool _isCurrent(Book candidate) {
    if (widget.book.sourceUrl.isNotEmpty &&
        candidate.sourceUrl == widget.book.sourceUrl) {
      return true;
    }
    return candidate.bookSourceUrl == widget.book.bookSourceUrl &&
        candidate.sourceUrl == widget.book.sourceUrl;
  }

  Future<void> _onSelect(Book selected) async {
    if (_applying) return;
    if (_isCurrent(selected)) {
      Navigator.pop(context, widget.book);
      return;
    }
    setState(() {
      _applying = true;
      _applyError = null;
    });
    try {
      final bookProvider = context.read<BookProvider>();
      final sourceProvider = context.read<SourceProvider>();
      final source = sourceProvider.findSourceForBook(selected);
      if (source == null) {
        throw StateError('找不到对应书源，请确认书源已启用');
      }
      final updated = await bookProvider.changeSource(
        widget.book,
        selected,
        source: source,
      );
      await bookProvider.loadChapters(
        updated,
        source: source,
        forceRefresh: true,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applyError = '$e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('换源失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('换源 · ${widget.book.name}'),
        actions: [
          IconButton(
            tooltip: '重新搜索',
            onPressed: _applying ? null : _startSearch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<SourceProvider>(
            builder: (context, provider, _) {
              final hasResults = provider.searchResults.isNotEmpty;

              if (provider.isLoading && !hasResults) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在搜索启用书源…'),
                    ],
                  ),
                );
              }

              if (!hasResults) {
                return EmptyState(
                  icon: Icons.search_off,
                  title: provider.statusMessage.isNotEmpty
                      ? provider.statusMessage
                      : '未找到可换源结果',
                  subtitle: '《${widget.book.name}》\n可下拉或点刷新重试',
                  actionLabel: '重新搜索',
                  onAction: _startSearch,
                );
              }

              final flat = <({String sourceUrl, Book book})>[];
              for (final e in provider.searchResults.entries) {
                for (final b in e.value) {
                  flat.add((sourceUrl: e.key, book: b));
                }
              }
              flat.sort((a, b) {
                final ca = _isCurrent(a.book);
                final cb = _isCurrent(b.book);
                if (ca != cb) return ca ? -1 : 1;
                return _sourceName(
                  provider,
                  a.sourceUrl,
                ).compareTo(_sourceName(provider, b.sourceUrl));
              });

              return Column(
                children: [
                  if (provider.isLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_applyError != null)
                    Material(
                      color: theme.colorScheme.errorContainer,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          _applyError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        provider.isLoading
                            ? '搜索中… 已找到 ${flat.length} 个结果'
                            : '共 ${flat.length} 个结果，点选即可换源',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: flat.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = flat[index];
                        final book = item.book;
                        final current = _isCurrent(book);
                        final sourceName = _sourceName(
                          provider,
                          item.sourceUrl,
                        );
                        final latest = _latestLine(book);
                        return ListTile(
                          enabled: !_applying,
                          selected: current,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: BookCover(
                            coverUrl: book.coverUrl,
                            author: book.author,
                            width: 48,
                            height: 64,
                            radius: 4,
                          ),
                          title: Text(
                            book.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (book.author.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (latest.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '最新：$latest',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  label: Text(
                                    sourceName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: current
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  side: BorderSide.none,
                                  backgroundColor: current
                                      ? theme.colorScheme.primaryContainer
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: current
                              ? Text(
                                  '当前',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                          onTap: () => _onSelect(book),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          if (_applying)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在换源并刷新目录…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
