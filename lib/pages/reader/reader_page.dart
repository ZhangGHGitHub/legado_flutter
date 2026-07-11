import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/read_book.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../book/toc_sheet.dart';
import '../reader/ai_chat_page.dart';
import 'reader_settings.dart';
import '../../widgets/bookplate_overlay.dart';

/// 阅读器页面
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
        _syncPreload();
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

  void _syncPreload() {
    final source = context.read<SourceProvider>().findSourceForBook(widget.book);
    if (source == null) return;
    final rb = ReadBook.instance;
    if (rb.book?.id != widget.book.id ||
        rb.chapters.length != widget.allChapters.length) {
      rb.open(
        currentBook: widget.book,
        source: source,
        chapterList: widget.allChapters,
        startIndex: _currentIndex,
      );
    } else {
      rb.durChapterIndex = _currentIndex;
      rb.preloadAdjacent();
    }
  }

  void _showTocSheet() {
    TocSheet.show(
      context,
      chapters: widget.allChapters,
      currentChapter: widget.allChapters[_currentIndex].title,
      onChapterTap: (chapter) {
        final idx = widget.allChapters.indexOf(chapter);
        if (idx >= 0) _goToChapter(idx);
      },
    );
  }

  List<Widget> _readerAppBarActions() {
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: '更多',
        onSelected: (v) {
          if (v == 'toc') _showTocSheet();
          if (v == 'settings') _showSettingsPanel();
          if (v == 'ai') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AiChatPage(isStandalone: false),
              ),
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'toc',
            child: ListTile(
              leading: Icon(Icons.list_alt, size: 20),
              title: Text('目录', style: TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'ai',
            child: ListTile(
              leading: Icon(Icons.smart_toy_outlined, size: 20),
              title: Text('AI 助手', style: TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: ListTile(
              leading: Icon(Icons.settings, size: 20),
              title: Text('阅读设置', style: TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  /// 打开阅读设置面板
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ReaderSettingsPanel(
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
        actions: _readerAppBarActions(),
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
            if (!_isLoading && _content != '加载中...')
              BookplateOverlay(textColor: theme.text, isHeader: true),
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
            if (!_isLoading && _content != '加载中...')
              BookplateOverlay(textColor: theme.text, isHeader: false),
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
        actions: _readerAppBarActions(),
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
                        BookplateOverlay(textColor: theme.text, isHeader: true),
                        SelectableText(
                          _content,
                          style: TextStyle(
                            fontSize: _settings.fontSize,
                            height: _settings.lineHeight,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BookplateOverlay(textColor: theme.text, isHeader: false),
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