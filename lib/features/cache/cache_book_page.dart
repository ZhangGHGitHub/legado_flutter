import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/cache/book_cache_export_port.dart';
import '../../application/cache/cache_book_shelf_port.dart';
import '../../application/source_management/source_notifier.dart';
import '../../domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../widgets/legado_popup_menu.dart';
import 'download_choice_dialog.dart';
import 'download_helpers.dart';

/// 离线缓存管理 — 对齐 Jingshiro `CacheActivity` + `item_download`
class CacheBookPage extends StatelessWidget {
  const CacheBookPage({super.key, required this.contentCache, this.shelfPort});

  final ChapterContentCachePort contentCache;
  final CacheBookShelfPort? shelfPort;

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.read<BookProvider>();
    final resolvedShelfPort =
        shelfPort ??
        CacheBookShelfPortCallbacks(
          books: () => bookProvider.books,
          getChapterCount: bookProvider.getChapterCount,
          getLocalChapters: bookProvider.getLocalChapters,
        );
    final sourceProvider = context.read<SourceProvider>();
    return riverpod.ProviderScope(
      overrides: [
        sourceControllerProvider.overrideWithValue(sourceProvider.controller),
      ],
      child: _CacheBookPageBody(
        contentCache: contentCache,
        shelfPort: resolvedShelfPort,
      ),
    );
  }
}

class _CacheBookPageBody extends riverpod.ConsumerStatefulWidget {
  const _CacheBookPageBody({
    required this.contentCache,
    required this.shelfPort,
  });

  final ChapterContentCachePort contentCache;
  final CacheBookShelfPort shelfPort;

  @override
  riverpod.ConsumerState<_CacheBookPageBody> createState() =>
      _CacheBookPageState();
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

class _CacheBookRow {
  final Book book;
  final int cachedChapters;
  final int totalChapters;
  final int bytes;

  const _CacheBookRow({
    required this.book,
    required this.cachedChapters,
    required this.totalChapters,
    required this.bytes,
  });

  String get sizeLabel => _formatBytes(bytes);
}

class _CacheBookPageState extends riverpod.ConsumerState<_CacheBookPageBody> {
  final Map<String, _CacheBookRow> _rows = {};
  final Set<String> _selected = {};
  bool _loading = true;
  bool _selectMode = false;
  String? _search;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final books = widget.shelfPort.books;
    setState(() => _loading = true);
    final map = <String, _CacheBookRow>{};
    for (final book in books) {
      final stats = await widget.contentCache.stats(book.id);
      final dbChapters = await widget.shelfPort.getChapterCount(book.id);
      map[book.id] = _CacheBookRow(
        book: book,
        cachedChapters: stats.chapterFiles,
        totalChapters: dbChapters > 0 ? dbChapters : stats.chapterFiles,
        bytes: stats.bytes,
      );
    }
    if (!mounted) return;
    setState(() {
      _rows
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  List<_CacheBookRow> get _visible {
    final list = _rows.values.toList()
      ..sort((a, b) => a.book.name.compareTo(b.book.name));
    final key = _search?.trim();
    if (key == null || key.isEmpty) return list;
    return list
        .where((r) => r.book.name.contains(key) || r.book.author.contains(key))
        .toList();
  }

  Future<void> _toggleDownload(Book book) async {
    final provider = context.read<BookProvider>();
    if (provider.isDownloading && provider.downloadBookId == book.id) {
      provider.cancelDownload();
      return;
    }
    if (provider.isDownloading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正在缓存其他书籍，请稍候')));
      return;
    }

    final source = ref
        .read(sourceNotifierProvider.notifier)
        .findSourceForBook(book);
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未找到书源，无法缓存')));
      return;
    }

    await provider.loadChapters(book, source: source);
    if (!mounted) return;
    final chapters = provider.currentChapters;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目录为空')));
      return;
    }

    final cachedIds = await widget.contentCache.listChapterIds(book.id);
    if (!mounted) return;
    final cachedCount = chapters
        .where(
          (c) =>
              c.isDownloaded ||
              cachedIds.contains(widget.contentCache.sanitizeChapterId(c.id)),
        )
        .length;

    final choice = await DownloadChoiceDialog.show(
      context,
      currentChapterIndex: book.currentChapter != null
          ? chapters
                .indexWhere((c) => c.title == book.currentChapter)
                .clamp(0, chapters.length - 1)
          : 0,
      totalChapters: chapters.length,
      cachedCount: cachedCount,
    );
    if (choice == null || !mounted) return;

    final toDownload = filterChaptersForDownload(
      chapters,
      choice,
      startIndex: book.currentChapter != null
          ? chapters
                .indexWhere((c) => c.title == book.currentChapter)
                .clamp(0, chapters.length - 1)
          : 0,
      cachedIds: cachedIds,
      sanitizeChapterId: widget.contentCache.sanitizeChapterId,
    );
    if (toDownload.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有需要缓存的章节')));
      return;
    }

    await provider.downloadAllChapters(
      book.id,
      toDownload,
      source,
      concurrency: choice.concurrency,
    );
    if (mounted) await _reload();
  }

  Future<void> _clearSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除缓存'),
        content: Text('确定清除已选 ${_selected.length} 本书的缓存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final id in _selected) {
      await widget.contentCache.clearBook(id);
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    await _reload();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除全部缓存'),
        content: const Text('确定清除所有书籍的正文缓存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.contentCache.clearAll();
    if (mounted) await _reload();
  }

  Future<void> _exportBooks(List<Book> books) async {
    if (books.isEmpty) return;
    final exporter = context.read<BookCacheExportPort?>();
    if (exporter == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('缓存导出引擎不可用')));
      }
      return;
    }
    final text = await exporter.buildBooksText(
      books: books,
      loadChapters: widget.shelfPort.getLocalChapters,
    );
    if (text.isEmpty || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('所选书籍没有可导出的缓存正文')));
      }
      return;
    }
    final defaultName = books.length == 1 ? books.single.name : 'legado-缓存导出';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '导出缓存正文',
      fileName: '$defaultName.txt',
      type: FileType.custom,
      allowedExtensions: const ['txt'],
      bytes: null,
    );
    if (path != null) {
      final file = File(path);
      await file.writeAsString(text, flush: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导出 ${file.path}')));
      }
      return;
    }
    await Share.share(text, subject: defaultName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<BookProvider>();
    final rows = _visible;

    return Scaffold(
      appBar: AppBar(
        title: _selectMode
            ? Text('已选 ${_selected.length}')
            : const Text('离线缓存'),
        actions: [
          if (!_selectMode)
            IconButton(
              tooltip: '搜索',
              icon: const Icon(Icons.search),
              onPressed: () async {
                final ctrl = TextEditingController(text: _search ?? '');
                final v = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('搜索'),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: '书名 / 作者'),
                      onSubmitted: (s) => Navigator.pop(ctx, s),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, ''),
                        child: const Text('清空'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
                if (v != null && mounted) {
                  setState(() => _search = v.trim().isEmpty ? null : v.trim());
                }
              },
            ),
          IconButton(
            tooltip: _selectMode ? '取消选择' : '多选',
            icon: Icon(_selectMode ? Icons.close : Icons.checklist),
            onPressed: () => setState(() {
              _selectMode = !_selectMode;
              if (!_selectMode) _selected.clear();
            }),
          ),
          if (_selectMode) ...[
            IconButton(
              tooltip: '导出所选',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: _selected.isEmpty
                  ? null
                  : () => _exportBooks(
                      _rows.values
                          .where((row) => _selected.contains(row.book.id))
                          .map((row) => row.book)
                          .toList(),
                    ),
            ),
            IconButton(
              tooltip: '清除所选',
              icon: const Icon(Icons.delete_outline),
              onPressed: _selected.isEmpty ? null : _clearSelected,
            ),
          ] else
            PopupMenuButton<String>(
              offset: legadoAppBarPopupOffset(context),
              onSelected: (v) {
                if (v == 'clear_all') _clearAll();
                if (v == 'reload') _reload();
                if (v == 'export_all') {
                  _exportBooks(_rows.values.map((r) => r.book).toList());
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'reload', child: Text('刷新')),
                PopupMenuItem(value: 'export_all', child: Text('导出全部缓存')),
                PopupMenuItem(value: 'clear_all', child: Text('清除全部缓存')),
              ],
            ),
        ],
        bottom: provider.isDownloading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: provider.downloadProgress > 0
                      ? provider.downloadProgress
                      : null,
                ),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? Center(
              child: Text(
                '书架暂无书籍',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final row = rows[i];
                  final book = row.book;
                  final downloading =
                      provider.isDownloading &&
                      provider.downloadBookId == book.id;
                  final isLocal = book.type == 'local';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: _selectMode
                        ? Checkbox(
                            value: _selected.contains(book.id),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(book.id);
                                } else {
                                  _selected.remove(book.id);
                                }
                              });
                            },
                          )
                        : null,
                    title: Text(
                      book.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '作者：${book.author}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLocal
                              ? '本地书籍'
                              : downloading
                              ? '缓存中 ${provider.downloadCompleted}/${provider.downloadTotal}'
                              : '已缓存 ${row.cachedChapters}/${row.totalChapters} · ${row.sizeLabel}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: isLocal || _selectMode
                        ? null
                        : IconButton(
                            tooltip: downloading ? '停止' : '下载',
                            icon: Icon(
                              downloading
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_circle_outline,
                            ),
                            onPressed: () => _toggleDownload(book),
                          ),
                    onTap: _selectMode
                        ? () {
                            setState(() {
                              if (_selected.contains(book.id)) {
                                _selected.remove(book.id);
                              } else {
                                _selected.add(book.id);
                              }
                            });
                          }
                        : isLocal
                        ? null
                        : () => _toggleDownload(book),
                    onLongPress: () {
                      setState(() {
                        _selectMode = true;
                        _selected.add(book.id);
                      });
                    },
                  );
                },
              ),
            ),
    );
  }
}
