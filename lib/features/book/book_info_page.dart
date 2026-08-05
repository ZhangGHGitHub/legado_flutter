import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:legado_flutter/application/book/book_info_chapter_port.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_membership_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/source/book_source_type.dart';
import '../../application/source_management/source_notifier.dart';
import '../../domain/ports/book_source_search_port.dart';
import '../../providers/book_provider.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../widgets/remote_binary_image.dart';
import '../../features/reader/reader_page.dart';
import '../reader/manga_reader_page.dart';
import 'change_cover_page.dart';
import 'change_source_page.dart';
import 'toc_sheet.dart';
import '../../utils/site_busy_guard.dart';

/// Legado 主色红（换源芯片 / 阅读按钮），对齐 Jingshiro BookInfo
const Color _kAccentRed = LegadoTokens.sourceDotRed;

/// 书籍详情 — 对齐 Jingshiro BookInfoActivity 截图布局
class BookInfoPage extends StatelessWidget {
  final Book book;
  final bool openReaderImmediately;
  final BookInfoChapterPort? chapterPort;
  final BookshelfMembershipPort? membershipPort;

  const BookInfoPage({
    super.key,
    required this.book,
    this.openReaderImmediately = false,
    this.chapterPort,
    this.membershipPort,
  });

  @override
  Widget build(BuildContext context) {
    return _BookInfoPageBody(
      book: book,
      openReaderImmediately: openReaderImmediately,
      chapterPort: chapterPort,
      membershipPort: membershipPort,
    );
  }
}

class _BookInfoPageBody extends riverpod.ConsumerStatefulWidget {
  final Book book;
  final bool openReaderImmediately;
  final BookInfoChapterPort? chapterPort;
  final BookshelfMembershipPort? membershipPort;

  const _BookInfoPageBody({
    required this.book,
    required this.openReaderImmediately,
    this.chapterPort,
    this.membershipPort,
  });

  @override
  riverpod.ConsumerState<_BookInfoPageBody> createState() =>
      _BookInfoPageState();
}

class _BookInfoPageState extends riverpod.ConsumerState<_BookInfoPageBody> {
  late Book _book;
  bool _isInShelf = false;
  String? _errorMessage;
  String _coverUrl = '';
  Timer? _snackBarHideTimer;
  bool _autoStartScheduled = false;
  late final BookInfoChapterPort _chapterPort;
  late final BookshelfMembershipPort _membershipPort;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    final provider = context.read<BookProvider>();
    _membershipPort =
        widget.membershipPort ??
        Provider.of<BookshelfMembershipPort?>(context, listen: false) ??
        const EmptyBookshelfMembershipPort();
    _chapterPort =
        widget.chapterPort ??
        Provider.of<BookInfoChapterPort?>(context, listen: false) ??
        BookInfoChapterPortCallbacks(
          currentChapters: () => provider.currentChapters,
          isLoading: () => provider.isLoading,
          isRefreshingToc: () => provider.isRefreshingToc,
          loadChapters: provider.loadChapters,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPage());
  }

  SourceNotifier get _sourceNotifier =>
      ref.read(sourceNotifierProvider.notifier);

  BookSource? _sourceForBook(Book book) =>
      _sourceNotifier.findSourceForBook(book);

  /// 保留旧版书架匹配优先级，仅把只读成员查询移到应用端口。
  Book? _findShelfBook(Book book) {
    for (final shelfBook in _membershipPort.books) {
      if (book.sourceUrl.isNotEmpty &&
          shelfBook.sourceUrl.isNotEmpty &&
          shelfBook.sourceUrl == book.sourceUrl) {
        return shelfBook;
      }
    }
    for (final shelfBook in _membershipPort.books) {
      if (shelfBook.name == book.name &&
          (book.author.isEmpty || shelfBook.author == book.author)) {
        return shelfBook;
      }
    }
    return null;
  }

  Future<void> _initPage() async {
    final bookProvider = context.read<BookProvider>();
    _coverUrl = _book.coverUrl;

    final shelf = _findShelfBook(_book);
    if (shelf != null) {
      _book = shelf;
      _isInShelf = true;
    } else {
      _isInShelf = false;
    }
    if (mounted) setState(() {});

    if (!mounted) return;
    setState(() => _errorMessage = null);
    final source = _sourceForBook(_book);
    if (source != null) {
      final cached = _chapterPort.currentChapters;
      final sameBook = cached.isNotEmpty && cached.first.bookId == _book.id;
      if (!sameBook) {
        try {
          await _chapterPort.loadChapters(_book, source: source);
        } catch (e) {
          if (mounted) {
            setState(() => _errorMessage = SiteBusyGuard.friendlyMessage(e));
          }
        }
      }
      if (_coverUrl.isEmpty && mounted) {
        await _fetchCoverFromSource(source);
      }
    }
    if (mounted && _chapterPort.currentChapters.isEmpty) {
      setState(() => _errorMessage ??= '未获取到章节列表\n请检查书源是否可用');
    }
    if (mounted &&
        widget.openReaderImmediately &&
        !_autoStartScheduled &&
        _chapterPort.currentChapters.isNotEmpty) {
      _autoStartScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startReading(bookProvider);
      });
    }
  }

  Future<void> _fetchCoverFromSource(BookSource source) async {
    try {
      final searchPort = context.read<BookSourceSearchPort>();
      final results = await searchPort.search(source, _book.name);
      String? foundCover;
      for (final r in results) {
        final name = r['name'] ?? '';
        final cover = r['coverUrl'] ?? '';
        if (cover.isEmpty) continue;
        if (name == _book.name) {
          foundCover = cover;
          break;
        }
        if (foundCover == null && name.contains(_book.name)) {
          foundCover = cover;
        }
      }
      if (foundCover != null && mounted) {
        setState(() => _coverUrl = foundCover!);
        if (_isInShelf && foundCover.isNotEmpty) {
          final next = await context.read<BookProvider>().updateBookCover(
            _book,
            foundCover,
          );
          if (mounted) setState(() => _book = next);
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshChapters({bool force = false}) async {
    final source = _sourceForBook(_book);
    if (source == null || !mounted) return;
    try {
      await _chapterPort.loadChapters(
        _book,
        source: source,
        forceRefresh: force,
      );
      if (mounted) setState(() => _errorMessage = null);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = SiteBusyGuard.friendlyMessage(e));
      }
    }
  }

  String get _resolvedCover {
    if (_book.coverUrl.isNotEmpty) return _book.coverUrl;
    return _coverUrl;
  }

  String _sourceDisplayName(List<BookSource> sources) {
    final sourceUrl = _book.bookSourceUrl;
    if (sourceUrl.isEmpty) return '未知书源';
    try {
      for (final s in sources) {
        if (s.bookSourceUrl == sourceUrl) {
          return s.bookSourceName;
        }
      }
    } catch (_) {}
    return Uri.tryParse(sourceUrl)?.host ?? sourceUrl;
  }

  String _originLabel() {
    if (_book.type == 'local') return '本地';
    final host =
        Uri.tryParse(_book.sourceUrl)?.host ??
        Uri.tryParse(_book.bookSourceUrl)?.host;
    if (host != null && host.isNotEmpty) return host;
    return '网络';
  }

  String _latestChapterLabel() {
    final last = _book.lastChapter;
    if (last != null && last.isNotEmpty) return last;
    if (_chapterPort.currentChapters.isNotEmpty) {
      return _chapterPort.currentChapters.last.title;
    }
    return '暂无';
  }

  String _tocPreviewLabel() {
    if (_chapterPort.currentChapters.isNotEmpty) {
      return _chapterPort.currentChapters.first.title;
    }
    return _book.currentChapter ?? '暂无';
  }

  Future<void> _addToShelf() async {
    final provider = context.read<BookProvider>();
    final existing = _findShelfBook(_book);
    if (existing != null) {
      if (mounted) {
        setState(() {
          _book = existing;
          _isInShelf = true;
        });
      }
      return;
    }
    await provider.addBook(_book);
    await provider.persistCurrentTocFor(_book);
    if (mounted) {
      setState(() => _isInShelf = true);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('《${_book.name}》已加入书架'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: '去阅读',
            onPressed: () {
              messenger.hideCurrentSnackBar();
              if (mounted) _startReading(provider);
            },
          ),
        ),
      );
      _snackBarHideTimer?.cancel();
      _snackBarHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) messenger.hideCurrentSnackBar();
      });
    }
  }

  Future<void> _removeFromShelf() async {
    final provider = context.read<BookProvider>();
    await provider.removeBook(_book.id);
    if (mounted) {
      setState(() => _isInShelf = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('已从书架移除《${_book.name}》'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isInShelf) {
      await _addToShelf();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除书籍'),
        content: Text('确定从书架删除「${_book.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kAccentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _removeFromShelf();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _downloadAllChapters(BookProvider provider) async {
    if (provider.isDownloading) {
      provider.cancelDownload();
      return;
    }
    final source = _sourceForBook(_book);
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未找到书源，无法缓存')));
      }
      return;
    }
    final chapters = _chapterPort.currentChapters;
    if (chapters.isEmpty) return;
    final toDownload = chapters.where((c) => !c.isDownloaded).toList();
    if (toDownload.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('所有章节已缓存')));
      }
      return;
    }
    provider.downloadAllChapters(_book.id, toDownload, source);
  }

  Future<void> _openChangeSource() async {
    final result = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => ChangeSourcePage(book: _book)),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _book = result;
        _coverUrl = result.coverUrl.isNotEmpty ? result.coverUrl : _coverUrl;
        _errorMessage = null;
      });
      final shelf = _findShelfBook(result);
      if (shelf != null) {
        setState(() {
          _book = shelf;
          _isInShelf = true;
          if (shelf.coverUrl.isNotEmpty) {
            _coverUrl = shelf.coverUrl;
          }
        });
      }
      return;
    }
    final shelf = _findShelfBook(_book);
    if (shelf != null) {
      setState(() {
        _book = shelf;
        _isInShelf = true;
        if (shelf.coverUrl.isNotEmpty) {
          _coverUrl = shelf.coverUrl;
        }
      });
    }
  }

  Future<void> _openChangeCover() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChangeCoverPage(book: _book)),
    );
    if (!mounted) return;
    final shelf = _findShelfBook(_book);
    if (shelf != null) {
      setState(() {
        _book = shelf;
        _coverUrl = shelf.coverUrl;
      });
    }
  }

  Future<void> _setGroup() async {
    if (!_isInShelf) {
      await _addToShelf();
      if (!mounted || !_isInShelf) return;
    }
    final groups =
        _membershipPort.books
            .map((b) => b.group)
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final controller = TextEditingController(text: _book.group);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '设置分组',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: '输入分组名（空=未分组）',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                ),
              ),
              ListTile(
                dense: true,
                title: const Text('未分组'),
                selected: _book.group.isEmpty,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              ...groups.map(
                (g) => ListTile(
                  dense: true,
                  title: Text(g),
                  selected: _book.group == g,
                  onTap: () => Navigator.pop(ctx, g),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kAccentRed,
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (chosen == null || !mounted) return;
    await context.read<BookProvider>().updateBookGroup(_book.id, chosen);
    if (mounted) {
      setState(() => _book = _book.copyWith(group: chosen));
    }
  }

  Future<void> _openToc() async {
    // 详情页已在拉目录时复用同一 Future，勿再起并行刷新
    if (_chapterPort.currentChapters.isEmpty) {
      if (_chapterPort.isLoading || _chapterPort.isRefreshingToc) {
        // 等待进行中的合并请求结束
        final source = _sourceForBook(_book);
        if (source != null) {
          try {
            await _chapterPort.loadChapters(_book, source: source);
          } catch (e) {
            if (mounted) {
              setState(() => _errorMessage = SiteBusyGuard.friendlyMessage(e));
            }
          }
        }
      } else {
        await _refreshChapters();
      }
    }
    if (!mounted) return;
    final chapters = _chapterPort.currentChapters;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage ?? '暂无目录')));
      return;
    }
    await TocSheet.show(
      context,
      chapters: chapters,
      currentChapter: _book.currentChapter,
      bookId: _book.id,
      onChapterTap: (chapter, {int? pageIndex, int? chapterPos}) async {
        Navigator.pop(context);
        final idx = chapters.indexWhere((c) => c.id == chapter.id);
        final source = _sourceForBook(_book);
        final useManga = source?.isImageSource ?? false;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => useManga
                ? MangaReaderPage(
                    book: _book,
                    chapters: chapters,
                    initialChapterIndex: idx < 0 ? 0 : idx,
                  )
                : ReaderPage(
                    book: _book,
                    chapter: chapter,
                    allChapters: chapters,
                    initialPageIndex: pageIndex,
                    initialChapterPos: chapterPos,
                  ),
          ),
        );
        if (mounted) _refreshChapters();
      },
    );
  }

  Future<void> _setReadIteration(int iteration) async {
    final next = _book.copyWith(readIteration: iteration);
    setState(() => _book = next);
    if (_isInShelf) {
      await context.read<BookProvider>().updateReadIteration(next, iteration);
    }
  }

  Future<void> _showReadStatusPicker() async {
    final current = _book.readIteration;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final options = <(int, String)>[
          (0, '清除标记'),
          (1, '读完'),
          (2, '2刷'),
          (3, '2刷完'),
          (4, '3刷'),
          (5, '3刷完'),
          (6, '4刷'),
          (7, '4刷完'),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '阅读状态',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
              ),
              ...options.map((o) {
                final (value, label) = o;
                return ListTile(
                  title: Text(label),
                  trailing: value == current
                      ? Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, value),
                );
              }),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) {
      await _setReadIteration(picked);
    }
  }

  Future<void> _editBookInfo() async {
    var name = _book.name;
    var author = _book.author;
    var description = _book.description;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑书籍'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                onChanged: (value) => name = value,
                decoration: const InputDecoration(labelText: '书名'),
              ),
              TextFormField(
                initialValue: author,
                onChanged: (value) => author = value,
                decoration: const InputDecoration(labelText: '作者'),
              ),
              TextFormField(
                initialValue: description,
                onChanged: (value) => description = value,
                decoration: const InputDecoration(labelText: '简介'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kAccentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      if (_isInShelf) {
        final next = await context.read<BookProvider>().updateBookDetails(
          _book.id,
          name: name,
          author: author,
          description: description,
        );
        if (next != null && mounted) setState(() => _book = next);
      } else {
        final trimmedName = name.trim();
        setState(
          () => _book = _book.copyWith(
            name: trimmedName.isEmpty ? _book.name : trimmedName,
            author: author.trim(),
            description: description.trim(),
          ),
        );
      }
    }
  }

  Future<void> _shareBook() async {
    final buf = StringBuffer('《${_book.name}》');
    if (_book.author.isNotEmpty) buf.write(' ${_book.author}');
    buf.writeln();
    if (_book.sourceUrl.isNotEmpty) {
      buf.writeln(_book.sourceUrl);
    } else if (_book.bookSourceUrl.isNotEmpty) {
      buf.writeln(_book.bookSourceUrl);
    }
    if (_book.description.isNotEmpty) {
      buf.writeln();
      buf.write(_book.description);
    }
    await Share.share(buf.toString(), subject: _book.name);
  }

  void _startReading(BookProvider provider) {
    final chapters = _chapterPort.currentChapters;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage ?? '暂无章节，无法阅读')));
      return;
    }
    final latestBook = provider.books.firstWhere(
      (b) => b.id == _book.id,
      orElse: () => _book,
    );
    Chapter startChapter;
    if (latestBook.currentChapter != null &&
        latestBook.currentChapter!.isNotEmpty) {
      final idx = chapters.indexWhere(
        (c) => c.title == latestBook.currentChapter,
      );
      startChapter = idx >= 0 ? chapters[idx] : chapters.first;
    } else {
      startChapter = chapters.first;
    }
    final chapterIndex = chapters
        .indexWhere((c) => c.id == startChapter.id)
        .clamp(0, chapters.length - 1);
    final source = _sourceForBook(latestBook);
    final useManga = source?.isImageSource ?? false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => useManga
            ? MangaReaderPage(
                book: latestBook,
                chapters: chapters,
                initialChapterIndex: chapterIndex,
              )
            : ReaderPage(
                book: latestBook,
                chapter: startChapter,
                allChapters: chapters,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _snackBarHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceState = ref.watch(sourceNotifierProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    const appBarH = kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '书籍信息',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        // 窄窗（Windows）三个 IconButton 会撑爆 trailing；编辑/分享并入溢出菜单
        actions: [
          PopupMenuButton<String>(
            offset: legadoAppBarPopupOffset(context),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) async {
              final provider = context.read<BookProvider>();
              switch (v) {
                case 'edit':
                  await _editBookInfo();
                case 'share':
                  await _shareBook();
                case 'cover':
                  await _openChangeCover();
                case 'status':
                  await _showReadStatusPicker();
                case 'refresh':
                  await _refreshChapters(force: true);
                case 'cache':
                  await _downloadAllChapters(provider);
                case 'toc':
                  await _openToc();
                case 'shelf':
                  if (_isInShelf) {
                    await _confirmDelete();
                  } else {
                    await _addToShelf();
                  }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              const PopupMenuItem(value: 'share', child: Text('分享')),
              const PopupMenuItem(value: 'cover', child: Text('更换封面')),
              const PopupMenuItem(value: 'status', child: Text('阅读状态')),
              const PopupMenuItem(value: 'refresh', child: Text('刷新目录')),
              const PopupMenuItem(value: 'cache', child: Text('缓存全部')),
              const PopupMenuItem(value: 'toc', child: Text('查看目录')),
              PopupMenuItem(
                value: 'shelf',
                child: Text(_isInShelf ? '删除书籍' : '加入书架'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<BookProvider>(
              builder: (context, provider, _) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(topPad + appBarH),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _book.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetaRows(provider, sourceState.sources),
                      if (_book.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSynopsis(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHero(double topInset) {
    final cover = _resolvedCover;
    return SizedBox(
      height: topInset + 168,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: const _HeroBottomCurveClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover.isNotEmpty)
                    RemoteBinaryImage(
                      url: cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: const Color(0xFF5A5A5A)),
                      placeholderBuilder: (_) =>
                          Container(color: const Color(0xFF5A5A5A)),
                    )
                  else
                    Container(color: const Color(0xFF5A5A5A)),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Center(
              child: Material(
                elevation: 6,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(6),
                child: BookCover(
                  coverUrl: cover,
                  author: _book.author,
                  width: 108,
                  height: 152,
                  radius: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRows(BookProvider provider, List<BookSource> sources) {
    final groupLabel = _book.group.isEmpty ? '未分组' : _book.group;
    final sourceText = '${_originLabel()} ${_sourceDisplayName(sources)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.person_outline,
            text: '作者：${_book.author.isEmpty ? '未知' : _book.author}',
          ),
          _MetaRow(
            icon: Icons.public,
            text: '来源：$sourceText',
            actionLabel: '换源',
            onAction: _openChangeSource,
          ),
          _MetaRow(
            icon: Icons.explore_outlined,
            text: '最新：${_latestChapterLabel()}',
          ),
          _MetaRow(
            icon: Icons.campaign_outlined,
            text: '分组：$groupLabel',
            actionLabel: '设置分组',
            onAction: _setGroup,
          ),
          _MetaRow(
            icon: Icons.folder_outlined,
            text: '目录：${_tocPreviewLabel()}',
            actionLabel: '查看目录',
            onAction: _openToc,
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsis() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Text(
        _book.description.trim(),
        textAlign: TextAlign.justify,
        style: TextStyle(fontSize: 14, height: 1.55, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: const Color(0xFFE8E8E8),
                  child: InkWell(
                    onTap: _confirmDelete,
                    child: Center(
                      child: Text(
                        _isInShelf ? '删除书籍' : '加入书架',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: _kAccentRed,
                  child: InkWell(
                    onTap: () => _startReading(context.read<BookProvider>()),
                    child: const Center(
                      child: Text(
                        '阅读',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.25,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            // 勿包 Flexible：默认 flex:1 会与左侧 Expanded 对半分宽，按钮无法贴右。
            _RedActionChip(label: actionLabel!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _RedActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RedActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kAccentRed,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 模糊头图底部浅凹弧，过渡到白色内容区（对齐 legado 截图）
class _HeroBottomCurveClipper extends CustomClipper<Path> {
  const _HeroBottomCurveClipper();

  @override
  Path getClip(Size size) {
    const dip = 22.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - dip);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + dip * 0.35,
      0,
      size.height - dip,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 兼容旧引用
class BookDetailPage extends StatelessWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) => BookInfoPage(book: book);
}
