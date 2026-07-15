import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../help/manga_image_extractor.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/manga_prefs.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/error_view.dart';

/// 漫画阅读器 — 对齐 Jingshiro [ReadMangaActivity] + `activity_manga.xml`
class MangaReaderPage extends StatefulWidget {
  final Book book;
  final List<Chapter> chapters;
  final int initialChapterIndex;
  final String? initialContent;

  const MangaReaderPage({
    super.key,
    required this.book,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.initialContent,
  });

  static Future<void> open(
    BuildContext context, {
    required Book book,
    required List<Chapter> chapters,
    int initialChapterIndex = 0,
    String? initialContent,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MangaReaderPage(
          book: book,
          chapters: chapters,
          initialChapterIndex: initialChapterIndex,
          initialContent: initialContent,
        ),
      ),
    );
  }

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  static const _chromeBg = Color(0xEE1A1A1A);
  static const _chromeFg = Colors.white;
  static const _accent = Color(0xFFFF6D00);

  late int _chapterIndex;
  List<String> _imageUrls = const [];
  int _pageIndex = 0;
  bool _loading = true;
  String? _error;
  bool _chromeVisible = false;
  bool _seeking = false;
  double _seekValue = 0;

  final _verticalController = ScrollController();
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialChapterIndex.clamp(
      0,
      math.max(0, widget.chapters.length - 1),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MangaPrefs.ensureLoaded();
      if (!mounted) return;
      setState(() {});
      await _loadChapter(seed: widget.initialContent);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _verticalController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  Chapter? get _chapter {
    if (widget.chapters.isEmpty) return null;
    return widget.chapters[_chapterIndex.clamp(0, widget.chapters.length - 1)];
  }

  bool get _isHorizontal =>
      MangaPrefs.direction != MangaReadDirection.vertical;

  bool get _isRtl =>
      MangaPrefs.direction == MangaReadDirection.rightToLeft;

  Future<void> _loadChapter({String? seed, bool resetPage = true}) async {
    if (widget.chapters.isEmpty) {
      setState(() {
        _loading = false;
        _error = '暂无章节';
        _imageUrls = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String content;
      if (seed != null && seed.isNotEmpty) {
        content = seed;
      } else {
        final chapter = widget.chapters[_chapterIndex];
        final bookProvider = context.read<BookProvider>();
        final source =
            context.read<SourceProvider>().findSourceForBook(widget.book);
        if (source == null) {
          throw StateError('未找到书源，无法加载漫画页');
        }
        content = await bookProvider.loadChapterContent(
          chapter.url,
          source: source,
          chapterId: chapter.id,
          bookId: widget.book.id,
        );
      }
      final base = _chapter?.url;
      final urls = MangaImageExtractor.extract(content, baseUrl: base);
      if (!mounted) return;
      if (urls.isEmpty) {
        setState(() {
          _loading = false;
          _error = content.trim().isEmpty
              ? '本章无内容'
              : '未解析到图片（引擎正文可能仍为占位文本）\n可换漫画源或稍后重试';
          _imageUrls = const [];
        });
        return;
      }
      _pageController?.dispose();
      _pageController = null;
      if (_isHorizontal) {
        _pageController = PageController(
          initialPage: resetPage ? 0 : _pageIndex.clamp(0, urls.length - 1),
        );
      }
      setState(() {
        _imageUrls = urls;
        _pageIndex = resetPage ? 0 : _pageIndex.clamp(0, urls.length - 1);
        _loading = false;
        _error = null;
      });
      _precacheNearby();
      unawaited(_persistProgress());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _imageUrls = const [];
      });
    }
  }

  void _precacheNearby() {
    if (!mounted || _imageUrls.isEmpty) return;
    final n = MangaPrefs.preDownloadNum;
    final start = _pageIndex;
    final end = math.min(_imageUrls.length, start + math.max(1, n));
    for (var i = start; i < end; i++) {
      precacheImage(NetworkImage(_imageUrls[i]), context);
    }
  }

  Future<void> _persistProgress() async {
    final ch = _chapter;
    if (ch == null) return;
    final total = math.max(1, widget.chapters.length);
    final progress = ((_chapterIndex + 1) / total).clamp(0.0, 1.0);
    await context.read<BookProvider>().updateProgress(
          widget.book.id,
          progress,
          ch.title,
          pageIndex: _pageIndex,
        );
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  Future<void> _skipChapter(int delta) async {
    final next = _chapterIndex + delta;
    if (next < 0 || next >= widget.chapters.length) return;
    setState(() => _chapterIndex = next);
    await _loadChapter();
  }

  void _goToPage(int index) {
    if (_imageUrls.isEmpty) return;
    final i = index.clamp(0, _imageUrls.length - 1);
    setState(() => _pageIndex = i);
    if (_isHorizontal && _pageController != null && _pageController!.hasClients) {
      _pageController!.jumpToPage(i);
    } else if (_verticalController.hasClients) {
      // 粗略跳转：按页均分估计
      final maxScroll = _verticalController.position.maxScrollExtent;
      final target =
          _imageUrls.length <= 1 ? 0.0 : maxScroll * (i / (_imageUrls.length - 1));
      _verticalController.jumpTo(target.clamp(0.0, maxScroll));
    }
    _precacheNearby();
  }

  void _onTapZone(TapUpDetails details) {
    if (_loading) return;
    final w = MediaQuery.sizeOf(context).width;
    final x = details.localPosition.dx;
    final left = x < w * 0.28;
    final right = x > w * 0.72;
    if (!left && !right) {
      _toggleChrome();
      return;
    }
    if (MangaPrefs.disableClickScroll) {
      _toggleChrome();
      return;
    }
    if (_isHorizontal) {
      final forward = _isRtl ? left : right;
      final next = forward ? _pageIndex + 1 : _pageIndex - 1;
      if (next < 0) {
        unawaited(_skipChapter(-1));
      } else if (next >= _imageUrls.length) {
        unawaited(_skipChapter(1));
      } else {
        _goToPage(next);
      }
    } else {
      // 纵向：左上章 / 右下章；中区菜单
      if (left) {
        unawaited(_skipChapter(-1));
      } else {
        unawaited(_skipChapter(1));
      }
    }
  }

  ColorFilter? _imageColorFilter() {
    if (MangaPrefs.enableEInk) {
      final t = MangaPrefs.eInkThreshold / 255.0;
      // 灰度 + 对比近似阈值
      final c = 1.0 + (t - 0.5) * 2.0;
      final o = 128 * (1 - c);
      return ColorFilter.matrix(<double>[
        0.2126 * c, 0.7152 * c, 0.0722 * c, 0, o,
        0.2126 * c, 0.7152 * c, 0.0722 * c, 0, o,
        0.2126 * c, 0.7152 * c, 0.0722 * c, 0, o,
        0, 0, 0, 1, 0,
      ]);
    }
    if (MangaPrefs.enableGray) {
      return const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    }
    final f = MangaPrefs.colorFilter;
    if (f.isIdentity) return null;
    final b = f.brightness.toDouble();
    return ColorFilter.matrix(<double>[
      1, 0, 0, 0, b,
      0, 1, 0, 0, b,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ]);
  }

  Widget _wrapFilter(Widget child) {
    final matrix = _imageColorFilter();
    final f = MangaPrefs.colorFilter;
    Widget w = child;
    if (matrix != null) {
      w = ColorFiltered(colorFilter: matrix, child: w);
    }
    if (!MangaPrefs.enableEInk &&
        !MangaPrefs.enableGray &&
        (f.a > 0 || f.r > 0 || f.g > 0 || f.b > 0)) {
      w = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color.fromARGB(f.a.clamp(0, 255), f.r, f.g, f.b),
          BlendMode.srcATop,
        ),
        child: w,
      );
    }
    return w;
  }

  Widget _buildImage(String url, {required bool fillWidth}) {
    final img = Image.network(
      url,
      fit: fillWidth ? BoxFit.fitWidth : BoxFit.contain,
      width: fillWidth ? double.infinity : null,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(
              color: _accent,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        height: 180,
        alignment: Alignment.center,
        color: Colors.black26,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 36),
            SizedBox(height: LegadoTokens.spacingSm),
            Text('图片加载失败', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );

    final filtered = _wrapFilter(img);
    if (MangaPrefs.disableScale) return filtered;

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: filtered,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () => unawaited(_loadChapter()),
        retryLabel: '重新加载',
        icon: Icons.image_not_supported_outlined,
      );
    }
    if (_imageUrls.isEmpty) {
      return ErrorView(
        message: '暂无图片',
        onRetry: () => unawaited(_loadChapter()),
        retryLabel: '重新加载',
      );
    }

    if (_isHorizontal) {
      return PageView.builder(
        controller: _pageController,
        reverse: _isRtl,
        itemCount: _imageUrls.length,
        onPageChanged: (i) {
          setState(() => _pageIndex = i);
          _precacheNearby();
          unawaited(_persistProgress());
        },
        itemBuilder: (_, i) => Center(
          child: _buildImage(_imageUrls[i], fillWidth: true),
        ),
      );
    }

    return ListView.builder(
      controller: _verticalController,
      padding: EdgeInsets.zero,
      itemCount: _imageUrls.length + (MangaPrefs.hideTitle ? 0 : 1),
      itemBuilder: (_, i) {
        if (!MangaPrefs.hideTitle && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              LegadoTokens.spacingMd,
              LegadoTokens.spacingSm,
              LegadoTokens.spacingMd,
              LegadoTokens.spacingSm,
            ),
            child: Text(
              _chapter?.title ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          );
        }
        final imgIndex = MangaPrefs.hideTitle ? i : i - 1;
        return _buildImage(_imageUrls[imgIndex], fillWidth: true);
      },
    );
  }

  Widget _infoBar() {
    if (_loading || _imageUrls.isEmpty) return const SizedBox.shrink();
    final ch = _chapter;
    final pageLabel =
        '${_pageIndex + 1}/${_imageUrls.length}';
    final chapLabel =
        '${_chapterIndex + 1}/${widget.chapters.length}';
    final pct = widget.chapters.isEmpty
        ? 0.0
        : (_chapterIndex + (_pageIndex + 1) / math.max(1, _imageUrls.length)) /
            widget.chapters.length;
    final pctLabel = '${(pct.clamp(0.0, 1.0) * 100).toStringAsFixed(1)}%';
    return Positioned(
      left: LegadoTokens.spacingMd,
      right: LegadoTokens.spacingMd,
      bottom: LegadoTokens.spacingMd,
      child: IgnorePointer(
        child: Text(
          '${ch?.title ?? ''}  $pageLabel  $chapLabel  $pctLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black87),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showColorFilterDialog() async {
    var cfg = MangaPrefs.colorFilter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LegadoDimens.radiusXLarge),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget slider(String title, int value, ValueChanged<int> onChanged) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title  $value',
                      style: const TextStyle(color: _chromeFg, fontSize: 13)),
                  Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    activeColor: _accent,
                    onChanged: (v) => setLocal(() => onChanged(v.round())),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '颜色滤镜',
                      style: TextStyle(
                        color: _chromeFg,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: LegadoTokens.spacingSm),
                    slider('亮度', cfg.brightness,
                        (v) => cfg = cfg.copyWith(brightness: v)),
                    slider('R', cfg.r, (v) => cfg = cfg.copyWith(r: v)),
                    slider('G', cfg.g, (v) => cfg = cfg.copyWith(g: v)),
                    slider('B', cfg.b, (v) => cfg = cfg.copyWith(b: v)),
                    slider('A', cfg.a, (v) => cfg = cfg.copyWith(a: v)),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setLocal(() => cfg = const MangaColorFilterConfig());
                          },
                          child: const Text('重置'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            await MangaPrefs.setColorFilter(cfg);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() {});
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEpaperDialog() async {
    var threshold = MangaPrefs.eInkThreshold;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LegadoDimens.radiusXLarge),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '墨水屏设置',
                      style: TextStyle(
                        color: _chromeFg,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: LegadoTokens.spacingSm),
                    Text('阈值  $threshold',
                        style: const TextStyle(color: _chromeFg)),
                    Slider(
                      value: threshold.toDouble(),
                      min: 0,
                      max: 255,
                      divisions: 255,
                      activeColor: _accent,
                      onChanged: (v) => setLocal(() => threshold = v.round()),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await MangaPrefs.setEInk(
                          enabled: true,
                          threshold: threshold,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) setState(() {});
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCatalog() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LegadoDimens.radiusXLarge),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (ctx, scroll) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        '目录（${widget.chapters.length}）',
                        style: const TextStyle(
                          color: _chromeFg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: _chromeFg),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: widget.chapters.length,
                    itemBuilder: (_, i) {
                      final ch = widget.chapters[i];
                      final active = i == _chapterIndex;
                      return ListTile(
                        dense: true,
                        selected: active,
                        selectedTileColor: Colors.white12,
                        title: Text(
                          ch.title,
                          style: TextStyle(
                            color: active ? _accent : _chromeFg,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, i),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (chosen != null && chosen != _chapterIndex) {
      setState(() => _chapterIndex = chosen);
      await _loadChapter();
    }
  }

  Future<void> _onMoreSelected(String value) async {
    switch (value) {
      case 'catalog':
        await _showCatalog();
      case 'refresh':
        await _loadChapter();
      case 'direction':
        await MangaPrefs.setDirection(MangaPrefs.direction.next);
        setState(() {
          _pageController?.dispose();
          _pageController = _isHorizontal
              ? PageController(initialPage: _pageIndex)
              : null;
        });
      case 'filter':
        await _showColorFilterDialog();
      case 'eink':
        final next = !MangaPrefs.enableEInk;
        await MangaPrefs.setEInk(enabled: next);
        setState(() {});
        if (next && mounted) await _showEpaperDialog();
      case 'gray':
        await MangaPrefs.setGray(!MangaPrefs.enableGray);
        setState(() {});
      case 'scale':
        await MangaPrefs.setDisableScale(!MangaPrefs.disableScale);
        setState(() {});
      case 'click':
        await MangaPrefs.setDisableClickScroll(!MangaPrefs.disableClickScroll);
        setState(() {});
      case 'title':
        await MangaPrefs.setHideTitle(!MangaPrefs.hideTitle);
        setState(() {});
      case 'predownload':
        final n = await _pickNumber(
          title: '预下载图片数',
          value: MangaPrefs.preDownloadNum,
          min: 0,
          max: 50,
        );
        if (n != null) {
          await MangaPrefs.setPreDownloadNum(n);
          _precacheNearby();
          setState(() {});
        }
    }
  }

  Future<int?> _pickNumber({
    required String title,
    required int value,
    required int min,
    required int max,
  }) async {
    var v = value;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$v'),
                  Slider(
                    value: v.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    onChanged: (x) => setLocal(() => v = x.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, v),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _topChrome() {
    final source = context.read<SourceProvider>().findSourceForBook(widget.book);
    return Material(
      color: _chromeBg,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: _chromeFg),
                  onPressed: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _chromeFg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _chapter?.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (source != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      source.bookSourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: _chromeFg),
                  onSelected: (v) => unawaited(_onMoreSelected(v)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'catalog', child: Text('目录')),
                    const PopupMenuItem(value: 'refresh', child: Text('刷新')),
                    PopupMenuItem(
                      value: 'direction',
                      child: Text('阅读方向：${MangaPrefs.direction.label}'),
                    ),
                    const PopupMenuItem(value: 'filter', child: Text('颜色滤镜')),
                    PopupMenuItem(
                      value: 'eink',
                      child: Text(MangaPrefs.enableEInk ? '关闭墨水屏' : '墨水屏模式'),
                    ),
                    PopupMenuItem(
                      value: 'gray',
                      child: Text(MangaPrefs.enableGray ? '关闭灰度' : '灰度'),
                    ),
                    PopupMenuItem(
                      value: 'scale',
                      child: Text(
                        MangaPrefs.disableScale ? '启用缩放' : '禁用缩放',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'click',
                      child: Text(
                        MangaPrefs.disableClickScroll ? '启用点击翻页' : '禁用点击翻页',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'title',
                      child: Text(
                        MangaPrefs.hideTitle ? '显示章节标题' : '隐藏章节标题',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'predownload',
                      child: Text('预下载：${MangaPrefs.preDownloadNum}'),
                    ),
                  ],
                ),
              ],
            ),
            if ((_chapter?.url ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _chapter!.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomChrome() {
    final canPrev = _chapterIndex > 0;
    final canNext = _chapterIndex + 1 < widget.chapters.length;
    final maxPage = math.max(0, _imageUrls.length - 1).toDouble();
    final value = (_seeking ? _seekValue : _pageIndex.toDouble())
        .clamp(0.0, math.max(maxPage, 0.0));

    return Material(
      color: _chromeBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
          child: Row(
            children: [
              TextButton(
                onPressed: canPrev ? () => unawaited(_skipChapter(-1)) : null,
                style: TextButton.styleFrom(
                  foregroundColor: _chromeFg,
                  disabledForegroundColor: Colors.white24,
                ),
                child: const Text('上一章'),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    activeTrackColor: _accent.withValues(alpha: 0.55),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: _accent,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxPage <= 0 ? 1 : maxPage,
                    divisions: maxPage > 0 ? maxPage.toInt() : null,
                    value: maxPage <= 0 ? 0.0 : value.toDouble(),
                    onChangeStart: (_) {
                      setState(() {
                        _seeking = true;
                        _seekValue = _pageIndex.toDouble();
                      });
                    },
                    onChanged: maxPage <= 0
                        ? null
                        : (v) => setState(() => _seekValue = v),
                    onChangeEnd: maxPage <= 0
                        ? null
                        : (v) {
                            setState(() => _seeking = false);
                            _goToPage(v.round());
                            unawaited(_persistProgress());
                          },
                  ),
                ),
              ),
              TextButton(
                onPressed: canNext ? () => unawaited(_skipChapter(1)) : null,
                style: TextButton.styleFrom(
                  foregroundColor: _chromeFg,
                  disabledForegroundColor: Colors.white24,
                ),
                child: const Text('下一章'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapZone,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBody(),
            if (!_chromeVisible) _infoBar(),
            if (_chromeVisible) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleChrome,
                  behavior: HitTestBehavior.translucent,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: _topChrome()),
              Positioned(bottom: 0, left: 0, right: 0, child: _bottomChrome()),
            ],
          ],
        ),
      ),
    );
  }
}
