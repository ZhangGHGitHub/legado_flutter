import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../models/book_source.dart';
import '../../models/chapter.dart';
import '../../database/database_helper.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/book_source_service.dart';
import '../../widgets/read_badge.dart';
import '../reader/reader_page.dart';
import 'change_cover_page.dart';
import 'change_source_page.dart';

/// 书籍详情 — 对齐 BookInfoActivity
class BookInfoPage extends StatefulWidget {
  final Book book;
  const BookInfoPage({super.key, required this.book});

  @override
  State<BookInfoPage> createState() => _BookInfoPageState();
}

class _BookInfoPageState extends State<BookInfoPage> {
  late Book _book;
  bool _isInShelf = false;
  String? _errorMessage;
  String _coverUrl = ''; // 可能从搜索获取的封面 URL
  final ScrollController _chapterScrollController = ScrollController();
  Timer? _snackBarHideTimer;
  bool _chapterReversed = false;
  bool _introExpanded = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPage());
  }

  Future<void> _initPage() async {
    final bookProvider = context.read<BookProvider>();
    final sourceProvider = context.read<SourceProvider>();
    _coverUrl = _book.coverUrl;

    // 书架书优先：按 sourceUrl/书名对齐到已落库 id，避免临时 id 导致目录永远冷加载
    final shelf = bookProvider.findShelfBook(_book);
    if (shelf != null) {
      _book = shelf;
      _isInShelf = true;
    } else {
      _isInShelf = false;
    }
    if (mounted) setState(() {});

    if (!mounted) return;
    setState(() => _errorMessage = null);
    final source = sourceProvider.findSourceForBook(_book);
    if (source != null) {
      final cached = bookProvider.currentChapters;
      final sameBook =
          cached.isNotEmpty && cached.first.bookId == _book.id;
      if (!sameBook) {
        await bookProvider.loadChapters(_book, source: source);
      }
      if (_coverUrl.isEmpty && mounted) {
        await _fetchCoverFromSource(source);
      }
    }
    if (mounted && bookProvider.currentChapters.isEmpty) {
      setState(() => _errorMessage = '未获取到章节列表\n请检查书源是否可用');
    }
  }

  /// 从书源搜索封面 URL
  Future<void> _fetchCoverFromSource(BookSource source) async {
    try {
      final service = BookSourceService();
      final results = await service.search(source, _book.name);
      // 先尝试精确匹配书名，再尝试包含匹配
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
        // 如果已加入书架，更新数据库
        if (_isInShelf && foundCover.isNotEmpty) {
          final db = DatabaseHelper();
          await db.updateBookCover(_book.id, foundCover);
        }
      }
    } catch (_) {
      // 封面获取失败不影响正常使用
    }
  }

  /// 刷新章节列表（从阅读器返回时调用）
  /// 默认只读本地/内存更新勾选，不强制联网（避免每次返回都卡很久）
  Future<void> _refreshChapters() async {
    final source = context.read<SourceProvider>().findSourceForBook(
      _book,
    );
    if (source != null && mounted) {
      await context.read<BookProvider>().loadChapters(
        _book,
        source: source,
      );
    }
  }

  /// 获取已下载的章节数
  int _downloadedCount(BookProvider provider) {
    return provider.currentChapters.where((c) => c.isDownloaded).length;
  }

  Future<void> _addToShelf() async {
    final provider = context.read<BookProvider>();
    // 绝不要换新 id：目录/正文缓存都按 bookId 索引（换 id = 永远冷加载）
    final existing = provider.findShelfBook(_book);
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
    // 已拉过的目录立刻落到本书 id 下
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
              if (mounted) {
                _startReading(provider);
              }
            },
          ),
        ),
      );
      _snackBarHideTimer?.cancel();
      _snackBarHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          messenger.hideCurrentSnackBar();
        }
      });
    }
  }

  /// 从书架移除
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

  /// 开始/继续/取消缓存章节
  Future<void> _downloadAllChapters(BookProvider provider) async {
    // 正在下载 → 取消
    if (provider.isDownloading) {
      provider.cancelDownload();
      return;
    }

    final source = context.read<SourceProvider>().findSourceForBook(
      _book,
    );
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未找到书源，无法缓存')));
      }
      return;
    }

    final chapters = provider.currentChapters;
    if (chapters.isEmpty) return;

    // 只下载未缓存的章节
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

  /// 章节列表加载后自动滚动到已读章节
  void _scrollToCurrentChapter(BookProvider provider) {
    if (!mounted || provider.currentChapters.isEmpty) return;
    final idx = provider.currentChapters.indexWhere(
      (c) => c.title == _book.currentChapter,
    );
    if (idx < 0 || !_chapterScrollController.hasClients) return;
    final visualIdx =
        _chapterReversed ? provider.currentChapters.length - 1 - idx : idx;
    final offset = visualIdx * 56.0; // ListTile 高度估算
    _chapterScrollController.animateTo(
      offset.clamp(0, _chapterScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openChangeSource() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChangeSourcePage(book: _book)),
    );
    if (!mounted) return;
    final shelf = context.read<BookProvider>().findShelfBook(_book);
    if (shelf != null) {
      setState(() {
        _book = shelf;
        _isInShelf = true;
      });
    }
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

  void _startReading(BookProvider provider) {
    if (provider.currentChapters.isEmpty) return;
    // 从 provider 中获取最新的 Book 数据（含 currentPageIndex）
    final latestBook = provider.books.firstWhere(
      (b) => b.id == _book.id,
      orElse: () => _book,
    );
    // 根据保存的进度定位上次阅读的章节
    Chapter startChapter;
    if (latestBook.currentChapter != null &&
        latestBook.currentChapter!.isNotEmpty) {
      final idx = provider.currentChapters.indexWhere(
        (c) => c.title == latestBook.currentChapter,
      );
      if (idx >= 0) {
        startChapter = provider.currentChapters[idx];
      } else {
        startChapter = provider.currentChapters.first;
      }
    } else {
      startChapter = provider.currentChapters.first;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: latestBook,
          chapter: startChapter,
          allChapters: provider.currentChapters,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _snackBarHideTimer?.cancel();
    _chapterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('书籍信息')),
      body: Column(
        children: [
          _buildBookHeader(theme),
          _buildActionButtons(),
          _buildSecondaryActions(),
          if (_book.description.isNotEmpty) _buildDescription(theme),
          const Divider(height: 1),
          _buildChapterListHeader(),
          Expanded(child: _buildChapterList()),
        ],
      ),
    );
  }

  Widget _buildBookHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 书籍封面
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 90,
              height: 130,
              child: _book.coverUrl.isNotEmpty
                  ? Image.network(
                      _book.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildCoverPlaceholder(theme),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildCoverPlaceholder(theme);
                      },
                    )
                  : _coverUrl.isNotEmpty
                  ? Image.network(
                      _coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildCoverPlaceholder(theme),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _buildCoverPlaceholder(theme);
                      },
                    )
                  : _buildCoverPlaceholder(theme),
            ),
          ),
          const SizedBox(width: 16),
          // 书籍信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _book.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (_book.author.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _book.author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                // 书源
                if (_book.bookSourceUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildSourceChip(_book.bookSourceUrl),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ReadBadge.fromBook(
                      _book,
                      onTap: _showReadStatusPicker,
                    ),
                    if (_book.readStatusLabel == null)
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('标记读完', style: TextStyle(fontSize: 11)),
                        avatar: const Icon(Icons.flag_outlined, size: 14),
                        onPressed: _showReadStatusPicker,
                      ),
                    if (_book.currentChapter != null)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '读到: ${_book.currentChapter}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                if (_book.progress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _book.progress,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(_book.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 封面占位（无封面或加载失败时显示）
  Widget _buildCoverPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 32, color: theme.colorScheme.primary),
          Text(
            _book.author.isNotEmpty
                ? _book.author.substring(
                    0,
                    _book.author.length > 4
                        ? 4
                        : _book.author.length,
                  )
                : '',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // 对齐 Jingshiro：加入书架 / 阅读 / 换源 并排主入口
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _isInShelf
                ? FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _removeFromShelf,
                    child: const Text('移出', overflow: TextOverflow.ellipsis),
                  )
                : FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: _addToShelf,
                    child: const Text('书架', overflow: TextOverflow.ellipsis),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => _startReading(context.read<BookProvider>()),
              child: Text(
                _book.progress > 0 ||
                        (_book.currentChapter?.isNotEmpty == true)
                    ? '继续'
                    : '阅读',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: _openChangeSource,
              child: const Text('换源', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 18),
          label: const Text('换封面'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeCoverPage(book: _book),
            ),
          ),
        ),
      ),
    );
  }

  /// 简介区域（可展开/收起）
  Widget _buildDescription(ThemeData theme) {
    final text = _book.description.trim();
    final canExpand = text.length > 72 || '\n'.allMatches(text).length >= 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '简介',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const Spacer(),
              if (canExpand)
                TextButton(
                  onPressed: () =>
                      setState(() => _introExpanded = !_introExpanded),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _introExpanded ? '收起' : '展开',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: canExpand
                ? () => setState(() => _introExpanded = !_introExpanded)
                : null,
            child: Text(
              text,
              maxLines: _introExpanded || !canExpand ? null : 3,
              overflow: _introExpanded || !canExpand
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 书源标签
  Widget _buildSourceChip(String sourceUrl) {
    String name;
    try {
      final sp = context.read<SourceProvider>();
      BookSource? found;
      for (final s in sp.sources) {
        if (s.bookSourceUrl == sourceUrl) {
          found = s;
          break;
        }
      }
      name =
          found?.bookSourceName ?? Uri.tryParse(sourceUrl)?.host ?? sourceUrl;
    } catch (_) {
      name = Uri.tryParse(sourceUrl)?.host ?? sourceUrl;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rss_feed, size: 10, color: Colors.blue[600]),
          const SizedBox(width: 3),
          Text(
            name,
            style: TextStyle(fontSize: 10, color: Colors.blue[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChapterListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.list_alt, size: 18),
          const SizedBox(width: 6),
          const Text('章节目录', style: TextStyle(fontWeight: FontWeight.w600)),
          TextButton.icon(
            onPressed: () => setState(() => _chapterReversed = !_chapterReversed),
            icon: Icon(
              _chapterReversed ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
            label: Text(
              _chapterReversed ? '正序' : '倒序',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          const Spacer(),
          Consumer<BookProvider>(
            builder: (context, provider, _) {
              final total = provider.currentChapters.length;
              final done = _downloadedCount(provider);

              // 下载中 → 进度 + 取消
              if (provider.isDownloading &&
                  provider.downloadBookId == _book.id) {
                return GestureDetector(
                  onTap: () => provider.cancelDownload(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.downloadCompleted}/${provider.downloadTotal} 取消',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 全部已缓存 → ✓
              if (total > 0 && done == total) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '共 $total 章',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[400],
                    ),
                  ],
                );
              }

              // 部分/未缓存 → 下载/继续按钮
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '共 $total 章',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (done > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '已缓存 $done',
                      style: TextStyle(fontSize: 11, color: Colors.green[400]),
                    ),
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _downloadAllChapters(provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            done > 0 ? Icons.downloading : Icons.download,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            done > 0 ? '继续缓存' : '缓存全部',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        // 章节列表加载完成后，自动滚动到已读位置
        if (provider.currentChapters.isNotEmpty && !provider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentChapter(provider);
          });
        }

        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载章节...'),
              ],
            ),
          );
        }

        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新加载'),
                  onPressed: () {
                    setState(() => _errorMessage = null);
                    final src = context
                        .read<SourceProvider>()
                        .findSourceForBook(_book);
                    if (src != null) {
                      provider.loadChapters(
                        _book,
                        source: src,
                        forceRefresh: true,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }

        final sourceChapters = provider.currentChapters;
        if (sourceChapters.isEmpty) {
          return Center(
            child: Text('暂无章节', style: TextStyle(color: Colors.grey[500])),
          );
        }

        final chapters = _chapterReversed
            ? sourceChapters.reversed.toList()
            : sourceChapters;
        final accent = Theme.of(context).colorScheme.primary;

        return ListView.separated(
          controller: _chapterScrollController,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: chapters.length,
          separatorBuilder: (context, i) =>
              const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final origIndex = sourceChapters.indexWhere((c) => c.id == chapter.id);
            final isCurrent = chapter.title == _book.currentChapter;
            return ListTile(
              dense: true,
              selected: isCurrent,
              selectedTileColor: accent.withValues(alpha: 0.12),
              leading: Text(
                '${(origIndex >= 0 ? origIndex : index) + 1}',
                style: TextStyle(
                  color: isCurrent ? accent : Colors.grey[500],
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              title: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCurrent ? accent : null,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: chapter.isDownloaded
                  ? Icon(Icons.check_circle, size: 16, color: Colors.green[400])
                  : Icon(
                      Icons.circle_outlined,
                      size: 16,
                      color: Colors.grey[300],
                    ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderPage(
                      book: _book,
                      chapter: chapter,
                      allChapters: sourceChapters,
                    ),
                  ),
                );
                // 从阅读器返回后刷新章节状态（阅读器可能自动缓存了章节）
                if (mounted) _refreshChapters();
              },
            );
          },
        );
      },
    );
  }
}

/// 兼容旧引用
class BookDetailPage extends StatelessWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) => BookInfoPage(book: book);
}
