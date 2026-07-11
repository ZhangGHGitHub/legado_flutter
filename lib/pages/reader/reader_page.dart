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

/// ═══════════════════════════════════════════════════
/// 书籍详情页 - 显示书籍信息 + 章节列表 + 加入书架
/// ═══════════════════════════════════════════════════
class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isInShelf = false;
  String? _errorMessage;
  String _coverUrl = ''; // 可能从搜索获取的封面 URL
  final ScrollController _chapterScrollController = ScrollController();
  Timer? _snackBarHideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPage());
  }

  Future<void> _initPage() async {
    final bookProvider = context.read<BookProvider>();
    final sourceProvider = context.read<SourceProvider>();
    _coverUrl = widget.book.coverUrl;
    final isInShelf = bookProvider.books.any((b) => b.name == widget.book.name);
    if (mounted) setState(() => _isInShelf = isInShelf);

    if (!mounted) return;
    setState(() => _errorMessage = null);
    final source = sourceProvider.findSourceForBook(widget.book);
    if (source != null) {
      await bookProvider.loadChapters(widget.book, source: source);
      // 如果封面为空，尝试从书源搜索封面
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
      final results = await service.search(source, widget.book.name);
      // 先尝试精确匹配书名，再尝试包含匹配
      String? foundCover;
      for (final r in results) {
        final name = r['name'] ?? '';
        final cover = r['coverUrl'] ?? '';
        if (cover.isEmpty) continue;
        if (name == widget.book.name) {
          foundCover = cover;
          break;
        }
        if (foundCover == null && name.contains(widget.book.name)) {
          foundCover = cover;
        }
      }
      if (foundCover != null && mounted) {
        setState(() => _coverUrl = foundCover!);
        // 如果已加入书架，更新数据库
        if (_isInShelf && foundCover.isNotEmpty) {
          final db = DatabaseHelper();
          await db.updateBookCover(widget.book.id, foundCover);
        }
      }
    } catch (_) {
      // 封面获取失败不影响正常使用
    }
  }

  /// 刷新章节列表（从阅读器返回时调用）
  Future<void> _refreshChapters() async {
    final source = context.read<SourceProvider>().findSourceForBook(
      widget.book,
    );
    if (source != null && mounted) {
      await context.read<BookProvider>().loadChapters(
        widget.book,
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
    final book = widget.book.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await provider.addBook(book);
    if (mounted) {
      setState(() => _isInShelf = true);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('《${widget.book.name}》已加入书架'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10), // 给 action 足够时间
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
      // 手动 3 秒后强制关闭（解决 Windows 上 SnackBar 不自动消失的 bug）
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
    await provider.removeBook(widget.book.id);
    if (mounted) {
      setState(() => _isInShelf = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('已从书架移除《${widget.book.name}》'),
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
      widget.book,
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

    provider.downloadAllChapters(widget.book.id, toDownload, source);
  }

  /// 章节列表加载后自动滚动到已读章节
  void _scrollToCurrentChapter(BookProvider provider) {
    if (!mounted || provider.currentChapters.isEmpty) return;
    final idx = provider.currentChapters.indexWhere(
      (c) => c.title == widget.book.currentChapter,
    );
    if (idx >= 0 && _chapterScrollController.hasClients) {
      final offset = idx * 56.0; // ListTile 高度估算
      _chapterScrollController.animateTo(
        offset.clamp(0, _chapterScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startReading(BookProvider provider) {
    if (provider.currentChapters.isEmpty) return;
    // 从 provider 中获取最新的 Book 数据（含 currentPageIndex）
    final latestBook = provider.books.firstWhere(
      (b) => b.id == widget.book.id,
      orElse: () => widget.book,
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
      appBar: AppBar(title: const Text('书籍详情')),
      body: Column(
        children: [
          _buildBookHeader(theme),
          _buildActionButtons(),
          if (widget.book.description.isNotEmpty) _buildDescription(theme),
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
              child: widget.book.coverUrl.isNotEmpty
                  ? Image.network(
                      widget.book.coverUrl,
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
                  widget.book.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.book.author.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        widget.book.author,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                // 书源
                if (widget.book.bookSourceUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildSourceChip(widget.book.bookSourceUrl),
                  ),
                const SizedBox(height: 8),
                if (widget.book.currentChapter != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '读到: ${widget.book.currentChapter}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.tertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (widget.book.progress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: widget.book.progress,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(widget.book.progress * 100).toInt()}%',
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
            widget.book.author.isNotEmpty
                ? widget.book.author.substring(
                    0,
                    widget.book.author.length > 4
                        ? 4
                        : widget.book.author.length,
                  )
                : '',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _isInShelf
                ? FilledButton.tonalIcon(
                    icon: const Icon(Icons.check, color: Colors.orange),
                    label: Text(
                      '移出书架',
                      style: const TextStyle(color: Colors.orange),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    ),
                    onPressed: _removeFromShelf,
                  )
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.add),
                    label: const Text('加入书架'),
                    onPressed: _addToShelf,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.menu_book),
              label: Text(
                widget.book.progress > 0 ||
                        (widget.book.currentChapter?.isNotEmpty == true)
                    ? '继续阅读'
                    : '开始阅读',
              ),
              onPressed: () => _startReading(context.read<BookProvider>()),
            ),
          ),
        ],
      ),
    );
  }

  /// 简介区域
  Widget _buildDescription(ThemeData theme) {
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
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.book.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.list_alt, size: 18),
          const SizedBox(width: 6),
          const Text('章节目录', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Consumer<BookProvider>(
            builder: (context, provider, _) {
              final total = provider.currentChapters.length;
              final done = _downloadedCount(provider);

              // 下载中 → 进度 + 取消
              if (provider.isDownloading &&
                  provider.downloadBookId == widget.book.id) {
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
                        .findSourceForBook(widget.book);
                    if (src != null) {
                      provider.loadChapters(widget.book, source: src);
                    }
                  },
                ),
              ],
            ),
          );
        }

        final chapters = provider.currentChapters;
        if (chapters.isEmpty) {
          return Center(
            child: Text('暂无章节', style: TextStyle(color: Colors.grey[500])),
          );
        }

        return ListView.separated(
          controller: _chapterScrollController,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: chapters.length,
          separatorBuilder: (context, i) =>
              const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final isCurrent = chapter.title == widget.book.currentChapter;
            return ListTile(
              dense: true,
              selected: isCurrent,
              selectedTileColor: Colors.blue.withValues(alpha: 0.08),
              leading: Text(
                '${index + 1}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              title: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                      book: widget.book,
                      chapter: chapter,
                      allChapters: chapters,
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

/// ═══════════════════════════════════════════════════
/// 阅读器设置数据模型
/// ═══════════════════════════════════════════════════
class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final String themeName; // 'paper' | 'white' | 'dark' | 'green'
  final String pageMode; // 'slide' | 'scroll'

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.themeName = 'paper',
    this.pageMode = 'slide',
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    String? themeName,
    String? pageMode,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      themeName: themeName ?? this.themeName,
      pageMode: pageMode ?? this.pageMode,
    );
  }
}

/// 阅读主题预设
class ReaderTheme {
  final Color background;
  final Color text;
  final Color appBar;
  final Color progress;

  const ReaderTheme({
    required this.background,
    required this.text,
    required this.appBar,
    required this.progress,
  });

  static const Map<String, ReaderTheme> themes = {
    'paper': ReaderTheme(
      background: Color(0xFFF5F0E8),
      text: Color(0xFF3C3C3C),
      appBar: Colors.white,
      progress: Colors.orange,
    ),
    'white': ReaderTheme(
      background: Colors.white,
      text: Color(0xFF333333),
      appBar: Colors.white,
      progress: Colors.blue,
    ),
    'dark': ReaderTheme(
      background: Color(0xFF1E1E1E),
      text: Color(0xFFCCCCCC),
      appBar: Color(0xFF2D2D2D),
      progress: Colors.tealAccent,
    ),
    'green': ReaderTheme(
      background: Color(0xFFC7EDCC),
      text: Color(0xFF2C4C3B),
      appBar: Color(0xFFE8F5E9),
      progress: Colors.green,
    ),
  };
}

/// ═══════════════════════════════════════════════════
/// 阅读器页面 - 增强版
/// ═══════════════════════════════════════════════════
class ReaderPage extends StatefulWidget {
  final Book book;
  final Chapter chapter;
  final List<Chapter> allChapters;

  const ReaderPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.allChapters,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  String _content = '加载中...';
  bool _isLoading = true;
  int _currentIndex = 0;
  int _pageIndex = 0;
  int? _pendingTargetPage; // 切换章节后要跳转到的页面索引
  List<String> _pages = [];
  late ReaderSettings _settings;
  late ScrollController _scrollController;
  PageController? _pageController;
  BookProvider? _bookProvider; // 缓存引用，避免 dispose 时 context.read 崩溃

  @override
  void initState() {
    super.initState();
    // 从 SharedPreferences 加载设置（后续实现持久化）
    _settings = const ReaderSettings();
    _scrollController = ScrollController();
    _currentIndex = widget.allChapters.indexOf(widget.chapter);
    if (_currentIndex < 0) _currentIndex = 0;
    // 恢复章内精确页面位置
    if (widget.book.currentPageIndex > 0) {
      _pendingTargetPage = widget.book.currentPageIndex;
    }
    _loadContent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookProvider = context.read<BookProvider>();
  }

  @override
  void dispose() {
    _saveProgress(); // 离开时保存进度（使用缓存的 _bookProvider）
    _scrollController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final chapter = widget.allChapters[_currentIndex];
      final source = context.read<SourceProvider>().findSourceForBook(
        widget.book,
      );
      String content;
      if (source != null) {
        content = await context.read<BookProvider>().loadChapterContentCached(
          chapter.url,
          source: source,
          chapterId: chapter.id,
          bookId: widget.book.id,
        );
      } else {
        content = '⚠️ 未找到匹配的书源';
      }
      if (mounted) {
        setState(() {
          _content = content.contains('（加载失败')
              ? '⚠️ 加载失败，请检查网络\n\n$content'
              : content;
          _isLoading = false;
          // 内容加载完后，等一帧让布局确定，再分页
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _settings.pageMode == 'slide') {
              _splitIntoPages();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _content = '⚠️ 无法加载章节内容\n\n请检查网络连接，或尝试其他书源。\n\n错误: $e';
        });
      }
    }
  }

  /// 将正文按屏幕高度拆分为独立页面
  void _splitIntoPages() {
    if (_content.isEmpty || !mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 可用宽度 = 屏幕宽度 - 左右 padding (40)
    final pageWidth =
        renderBox.size.width -
        40 -
        MediaQuery.of(context).padding.left -
        MediaQuery.of(context).padding.right;
    // 可用高度 = 可视区域 - appbar - 章节标题 - 底部进度条
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final chapterTitleHeight = _settings.fontSize + 28.0;
    final progressHeight = 36.0;
    final pageHeight =
        renderBox.size.height -
        appBarHeight -
        chapterTitleHeight -
        progressHeight -
        60;

    if (pageWidth <= 0 || pageHeight <= 0) {
      _pages = [_content];
      return;
    }

    final tp = TextPainter(
      text: TextSpan(
        text: _content,
        style: TextStyle(
          fontSize: _settings.fontSize,
          height: _settings.lineHeight,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: pageWidth);

    final totalHeight = tp.height;
    if (totalHeight <= pageHeight) {
      _pages = [_content];
      return;
    }

    final result = <String>[];
    int startOffset = 0;
    int pageNum = 1;

    while (startOffset < _content.length) {
      final targetY = pageNum * pageHeight;
      if (targetY >= totalHeight) {
        result.add(_content.substring(startOffset));
        break;
      }
      final pos = tp.getPositionForOffset(Offset(0.0, targetY));
      if (pos.offset <= startOffset) {
        result.add(_content.substring(startOffset));
        break;
      }
      result.add(_content.substring(startOffset, pos.offset));
      startOffset = pos.offset;
      pageNum++;
    }

    if (result.isEmpty) result.add(_content);

    _pageController?.dispose();
    final targetPage = _pendingTargetPage ?? 0;
    final clampedPage = targetPage < 0
        ? result.length - 1
        : (targetPage >= result.length ? 0 : targetPage);
    _pageController = PageController(initialPage: clampedPage);
    setState(() {
      _pages = result;
      _pageIndex = clampedPage;
      _pendingTargetPage = null; // 消费完毕
    });
    debugPrint(
      '📖 分页完成: ${result.length} 页 (目标=$clampedPage, 总高度=$totalHeight, 页高=$pageHeight)',
    );
  }

  /// 自动保存阅读进度
  void _saveProgress() {
    final bp = _bookProvider;
    if (bp == null) return;
    final progress = (_currentIndex + 1) / widget.allChapters.length;
    final currentChapter = widget.allChapters[_currentIndex].title;
    final pageIdx = _settings.pageMode == 'slide' ? _pageIndex : 0;
    bp.updateProgress(
      widget.book.id,
      progress,
      currentChapter,
      pageIndex: pageIdx,
    );
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.allChapters.length) return;
    _saveProgress();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _pageController?.dispose();
    _pageController = null;
    // 保留旧页面内容，避免加载时空白闪烁；只清除分页
    _pages = [];
    _pageIndex = 0;
    setState(() => _currentIndex = index);
    _loadContent();
  }

  /// 打开阅读设置面板
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ReaderSettingsPanel(
        settings: _settings,
        onChanged: (newSettings) {
          setState(() {
            _settings = newSettings;
            // 字体/行距变化 → 重新分页
            if (newSettings.pageMode == 'slide' &&
                !_isLoading &&
                _content.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _splitIntoPages();
              });
            }
          });
        },
      ),
    );
  }

  ReaderTheme get _currentTheme =>
      ReaderTheme.themes[_settings.themeName] ?? ReaderTheme.themes['paper']!;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.allChapters[_currentIndex];
    final theme = _currentTheme;

    if (_settings.pageMode == 'scroll') {
      return _buildScrollMode(chapter, theme);
    }
    return _buildSlideMode(chapter, theme);
  }

  /// 滑动翻页模式
  Widget _buildSlideMode(Chapter chapter, ReaderTheme theme) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBar.withValues(alpha: 0.95),
        title: const Text('阅读', style: TextStyle(fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveProgress();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '阅读设置',
            onPressed: _showSettingsPanel,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 加载进度条（切换章节时显示，首次加载无旧内容不显示）
            if (_isLoading && _content != '加载中...')
              LinearProgressIndicator(
                backgroundColor: theme.text.withValues(alpha: 0.1),
                color: theme.progress,
                minHeight: 2,
              ),
            // 章节标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                chapter.title,
                style: TextStyle(
                  fontSize: _settings.fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 8),
            Expanded(
              child: _isLoading && _content == '加载中...'
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.text),
                          const SizedBox(height: 16),
                          Text(
                            '加载中...',
                            style: TextStyle(
                              color: theme.text.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _pages.isEmpty
                  ? Center(
                      child: SelectableText(
                        _content,
                        style: TextStyle(
                          fontSize: _settings.fontSize,
                          height: _settings.lineHeight,
                          color: theme.text,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // 分页阅读区域
                        Expanded(
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _pages.length,
                                onPageChanged: (index) {
                                  setState(() => _pageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  return ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(
                                      context,
                                    ).copyWith(scrollbars: false),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: SelectableText(
                                        _pages[index],
                                        style: TextStyle(
                                          fontSize: _settings.fontSize,
                                          height: _settings.lineHeight,
                                          color: theme.text,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // 左侧透明点击区 → 上一页
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: GestureDetector(
                                  onTap: _prevPage,
                                  behavior: HitTestBehavior.translucent,
                                ),
                              ),
                              // 右侧透明点击区 → 下一页
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: GestureDetector(
                                  onTap: _nextPage,
                                  behavior: HitTestBehavior.translucent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            // 底部进度
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_currentIndex + 1}/${widget.allChapters.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.text.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _pages.isEmpty
                            ? (_currentIndex + 1) / widget.allChapters.length
                            : (_pageIndex + 1) / _pages.length,
                        minHeight: 3,
                        backgroundColor: theme.text.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(theme.progress),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _pages.isEmpty
                        ? '${_currentIndex + 1}章'
                        : '${_pageIndex + 1}/${_pages.length}页',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.text.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 左右翻页：上一页
  void _prevPage() {
    if (_pageController == null || _pages.isEmpty) return;
    if (_pageIndex > 0) {
      _pageController!.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else if (_currentIndex > 0) {
      _pendingTargetPage = -1; // 上一章最后一页
      _goToChapter(_currentIndex - 1);
    }
  }

  /// 左右翻页：下一页
  void _nextPage() {
    if (_pageController == null || _pages.isEmpty) return;
    if (_pageIndex < _pages.length - 1) {
      _pageController!.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else if (_currentIndex < widget.allChapters.length - 1) {
      _pendingTargetPage = 0; // 下一章第一页
      _goToChapter(_currentIndex + 1);
    }
  }

  /// 滚动翻页模式（像网页阅读一样）
  Widget _buildScrollMode(Chapter chapter, ReaderTheme theme) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBar.withValues(alpha: 0.95),
        title: const Text('阅读', style: TextStyle(fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveProgress();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '阅读设置',
            onPressed: _showSettingsPanel,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.text),
                    const SizedBox(height: 16),
                    Text(
                      '加载中...',
                      style: TextStyle(
                        color: theme.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: NotificationListener<ScrollNotification>(
                  key: ValueKey('scroll_$_currentIndex'),
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      final pixels = _scrollController.position.pixels;
                      final maxExt = _scrollController.position.maxScrollExtent;
                      debugPrint('📖 下滑翻页: ScrollEnd px=$pixels max=$maxExt');
                      if (pixels >= maxExt - 100) {
                        if (_currentIndex < widget.allChapters.length - 1) {
                          debugPrint(
                            '📖 下滑翻页: 到底, 跳下一章 $_currentIndex → ${_currentIndex + 1}',
                          );
                          _goToChapter(_currentIndex + 1);
                        }
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 章节标题
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            chapter.title,
                            style: TextStyle(
                              fontSize: _settings.fontSize + 6,
                              fontWeight: FontWeight.bold,
                              color: theme.text,
                            ),
                          ),
                        ),
                        SelectableText(
                          _content,
                          style: TextStyle(
                            fontSize: _settings.fontSize,
                            height: _settings.lineHeight,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 底部翻页按钮
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_currentIndex > 0)
                                OutlinedButton(
                                  onPressed: () =>
                                      _goToChapter(_currentIndex - 1),
                                  child: const Text('← 上一章'),
                                ),
                              const SizedBox(width: 16),
                              if (_currentIndex < widget.allChapters.length - 1)
                                OutlinedButton(
                                  onPressed: () =>
                                      _goToChapter(_currentIndex + 1),
                                  child: const Text('下一章 →'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════
/// 阅读设置面板（底部弹窗）
/// ═══════════════════════════════════════════════════
class _ReaderSettingsPanel extends StatefulWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderSettings> onChanged;

  const _ReaderSettingsPanel({required this.settings, required this.onChanged});

  @override
  State<_ReaderSettingsPanel> createState() => _ReaderSettingsPanelState();
}

class _ReaderSettingsPanelState extends State<_ReaderSettingsPanel> {
  late ReaderSettings _s;

  @override
  void initState() {
    super.initState();
    _s = widget.settings;
  }

  void _update(ReaderSettings s) {
    setState(() => _s = s);
    widget.onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 + 关闭按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Text(
                  '阅读设置',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // ── 字体大小 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('字体大小', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.text_fields, size: 20),
                    Expanded(
                      child: Slider(
                        value: _s.fontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        label: '${_s.fontSize.toInt()}',
                        onChanged: (v) => _update(_s.copyWith(fontSize: v)),
                      ),
                    ),
                    Text(
                      '${_s.fontSize.toInt()}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 行距 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('行距', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _s.lineHeight,
                        min: 1.2,
                        max: 2.5,
                        divisions: 13,
                        label: _s.lineHeight.toStringAsFixed(1),
                        onChanged: (v) => _update(_s.copyWith(lineHeight: v)),
                      ),
                    ),
                    Text(
                      _s.lineHeight.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 翻页模式 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('翻页模式', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ModeChip(
                      icon: Icons.swipe,
                      label: '左右翻页',
                      selected: _s.pageMode == 'slide',
                      onTap: () => _update(_s.copyWith(pageMode: 'slide')),
                    ),
                    const SizedBox(width: 12),
                    _ModeChip(
                      icon: Icons.unfold_more,
                      label: '下滑翻页',
                      selected: _s.pageMode == 'scroll',
                      onTap: () => _update(_s.copyWith(pageMode: 'scroll')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 阅读主题 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('阅读主题', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ThemeDot(
                      color: const Color(0xFFF5F0E8),
                      name: '米黄',
                      selected: _s.themeName == 'paper',
                      onTap: () => _update(_s.copyWith(themeName: 'paper')),
                    ),
                    _ThemeDot(
                      color: Colors.white,
                      name: '白',
                      selected: _s.themeName == 'white',
                      onTap: () => _update(_s.copyWith(themeName: 'white')),
                    ),
                    _ThemeDot(
                      color: const Color(0xFF1E1E1E),
                      name: '暗黑',
                      selected: _s.themeName == 'dark',
                      onTap: () => _update(_s.copyWith(themeName: 'dark')),
                    ),
                    _ThemeDot(
                      color: const Color(0xFFC7EDCC),
                      name: '护眼绿',
                      selected: _s.themeName == 'green',
                      onTap: () => _update(_s.copyWith(themeName: 'green')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 翻页模式选择标签
class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 主题色圆点选择器
class _ThemeDot extends StatelessWidget {
  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: selected ? 3 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
