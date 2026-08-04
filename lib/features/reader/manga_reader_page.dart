import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application/reader/manga_chapter_content_port.dart';
import '../../application/reader/manga_chapter_list_port.dart';
import '../../application/reader/manga_prefs_port.dart';
import '../../application/reader/manga_progress_port.dart';
import '../../application/reader/manga_source_presentation_port.dart';
import '../../application/reader/reader_chapter_content_port.dart';
import '../../help/manga_image_extractor.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../../providers/source_provider.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../widgets/remote_binary_image.dart';
import '../book/change_source_page.dart';
import '../book/toc_sheet.dart';

/// 漫画阅读器 — 1:1 对齐 Jingshiro [ReadMangaActivity] + `activity_manga.xml`
/// + [MangaMenu]/`view_manga_menu.xml`) + [ReaderInfoBarView] + `menu/book_manga.xml`
class MangaReaderPage extends StatefulWidget {
  final Book book;
  final List<Chapter> chapters;
  final int initialChapterIndex;
  final String? initialContent;
  final MangaChapterContentPort? contentPort;
  final MangaChapterListPort? chapterListPort;
  final MangaPrefsPort? prefs;
  final MangaProgressPort? progressPort;
  final MangaSourcePresentationPort? sourcePresentationPort;

  const MangaReaderPage({
    super.key,
    required this.book,
    required this.chapters,
    this.initialChapterIndex = 0,
    this.initialContent,
    this.contentPort,
    this.chapterListPort,
    this.prefs,
    this.progressPort,
    this.sourcePresentationPort,
  });

  static Future<void> open(
    BuildContext context, {
    required Book book,
    required List<Chapter> chapters,
    int initialChapterIndex = 0,
    String? initialContent,
    MangaChapterContentPort? contentPort,
    MangaChapterListPort? chapterListPort,
    MangaPrefsPort? prefs,
    MangaProgressPort? progressPort,
    MangaSourcePresentationPort? sourcePresentationPort,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MangaReaderPage(
          book: book,
          chapters: chapters,
          initialChapterIndex: initialChapterIndex,
          initialContent: initialContent,
          contentPort: contentPort,
          chapterListPort: chapterListPort,
          prefs: prefs,
          progressPort: progressPort,
          sourcePresentationPort: sourcePresentationPort,
        ),
      ),
    );
  }

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage>
    with SingleTickerProviderStateMixin {
  late final MangaPrefsPort _prefs;
  late final MangaChapterContentPort _contentPort;
  late final MangaChapterListPort _chapterListPort;
  late final MangaProgressPort? _progressPort;
  late final MangaSourcePresentationPort _sourcePresentationPort;
  late int _chapterIndex;
  List<String> _imageUrls = const [];
  Map<String, String> _imageHeaders = const {};
  int _pageIndex = 0;
  bool _loading = true;
  String? _error;
  bool _chromeVisible = false;
  bool _seeking = false;
  double _seekValue = 0;
  bool _autoPageEnabled = false;
  Timer? _autoPageTimer;
  Timer? _clockTimer;
  String _clockText = '';

  final _verticalController = ScrollController();
  PageController? _pageController;
  late final AnimationController _menuAnim;

  @override
  void initState() {
    super.initState();
    _prefs = widget.prefs ?? context.read<MangaPrefsPort>();
    _contentPort = _resolveContentPort();
    _chapterListPort =
        widget.chapterListPort ??
        Provider.of<MangaChapterListPort?>(context, listen: false) ??
        const EmptyMangaChapterListPort();
    _progressPort =
        widget.progressPort ??
        Provider.of<MangaProgressPort?>(context, listen: false);
    _sourcePresentationPort =
        widget.sourcePresentationPort ??
        Provider.of<MangaSourcePresentationPort?>(context, listen: false) ??
        const EmptyMangaSourcePresentationPort();
    _chapterIndex = widget.initialChapterIndex.clamp(
      0,
      math.max(0, widget.chapters.length - 1),
    );
    _menuAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _tickClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _tickClock(),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prefs.ensureLoaded();
      if (!mounted) return;
      setState(() {});
      await _loadChapter(seed: widget.initialContent);
    });
  }

  MangaChapterContentPort _resolveContentPort() {
    final explicitPort = widget.contentPort;
    if (explicitPort != null) return explicitPort;

    final mangaPort = Provider.of<MangaChapterContentPort?>(
      context,
      listen: false,
    );
    if (mangaPort != null) return mangaPort;

    final readerPort = Provider.of<ReaderChapterContentPort?>(
      context,
      listen: false,
    );
    if (readerPort == null) return const EmptyMangaChapterContentPort();

    return ReaderBackedMangaChapterContentPort(readerPort);
  }

  @override
  void dispose() {
    _autoPageTimer?.cancel();
    _clockTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _menuAnim.dispose();
    _verticalController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _tickClock() {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    if (!mounted) {
      _clockText = '$h:$m';
      return;
    }
    setState(() => _clockText = '$h:$m');
  }

  Chapter? get _chapter {
    if (widget.chapters.isEmpty) return null;
    return widget.chapters[_chapterIndex.clamp(0, widget.chapters.length - 1)];
  }

  bool get _isHorizontal => _prefs.direction != MangaReadDirection.vertical;

  bool get _isRtl => _prefs.direction == MangaReadDirection.rightToLeft;

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
    final sourceProvider = context.read<SourceProvider>();
    try {
      String content;
      if (seed != null && seed.isNotEmpty) {
        content = seed;
      } else {
        final chapter = widget.chapters[_chapterIndex];
        content = await _contentPort.loadChapterContent(
          book: widget.book,
          chapter: chapter,
        );
      }
      final base = _chapter?.url;
      final urls = MangaImageExtractor.extract(content, baseUrl: base);
      final imageHeaders = await sourceProvider.imageHeadersForBook(
        widget.book,
      );
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
        _imageHeaders = imageHeaders;
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
    final n = _prefs.preDownloadNum;
    final start = _pageIndex;
    final end = math.min(_imageUrls.length, start + math.max(1, n));
    for (var i = start; i < end; i++) {
      unawaited(_prefetchImage(_imageUrls[i]));
    }
  }

  Future<void> _prefetchImage(String url) async {
    try {
      await RemoteBinaryImage.prefetch(
        context,
        url: url,
        headers: _imageHeaders,
      );
    } catch (_) {
      // Display path keeps the existing broken-image fallback.
    }
  }

  Future<void> _persistProgress() async {
    final ch = _chapter;
    if (ch == null) return;
    final total = math.max(1, widget.chapters.length);
    final progress = ((_chapterIndex + 1) / total).clamp(0.0, 1.0);
    await _progressPort?.updateProgress(
      widget.book.id,
      progress,
      ch.title,
      pageIndex: _pageIndex,
      durChapterIndex: _chapterIndex,
    );
  }

  void _toggleChrome() {
    if (_chromeVisible) {
      _runMenuOut();
    } else {
      _runMenuIn();
    }
  }

  void _runMenuIn() {
    setState(() => _chromeVisible = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _menuAnim.forward(from: 0);
  }

  void _runMenuOut() {
    _menuAnim.reverse().whenComplete(() {
      if (!mounted) return;
      setState(() => _chromeVisible = false);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
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
    if (_isHorizontal &&
        _pageController != null &&
        _pageController!.hasClients) {
      if (_prefs.disablePageAnim) {
        _pageController!.jumpToPage(i);
      } else {
        _pageController!.animateToPage(
          i,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } else if (_verticalController.hasClients) {
      final maxScroll = _verticalController.position.maxScrollExtent;
      final target = _imageUrls.length <= 1
          ? 0.0
          : maxScroll * (i / (_imageUrls.length - 1));
      _verticalController.jumpTo(target.clamp(0.0, maxScroll));
    }
    _precacheNearby();
  }

  void _onTapZone(TapUpDetails details) {
    if (_loading || _chromeVisible) return;
    final w = MediaQuery.sizeOf(context).width;
    final x = details.localPosition.dx;
    final left = x < w * 0.28;
    final right = x > w * 0.72;
    if (!left && !right) {
      _toggleChrome();
      return;
    }
    if (_prefs.disableClickScroll) {
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
      if (left) {
        unawaited(_skipChapter(-1));
      } else {
        unawaited(_skipChapter(1));
      }
    }
  }

  ColorFilter? _imageColorFilter() {
    if (_prefs.enableEInk) {
      final t = _prefs.eInkThreshold / 255.0;
      final c = 1.0 + (t - 0.5) * 2.0;
      final o = 128 * (1 - c);
      return ColorFilter.matrix(<double>[
        0.2126 * c,
        0.7152 * c,
        0.0722 * c,
        0,
        o,
        0.2126 * c,
        0.7152 * c,
        0.0722 * c,
        0,
        o,
        0.2126 * c,
        0.7152 * c,
        0.0722 * c,
        0,
        o,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    if (_prefs.enableGray) {
      return const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    final f = _prefs.colorFilter;
    if (f.isIdentity) return null;
    final b = f.brightness.toDouble();
    return ColorFilter.matrix(<double>[
      1,
      0,
      0,
      0,
      b,
      0,
      1,
      0,
      0,
      b,
      0,
      0,
      1,
      0,
      b,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  Widget _wrapFilter(Widget child) {
    final matrix = _imageColorFilter();
    final f = _prefs.colorFilter;
    Widget w = child;
    if (matrix != null) {
      w = ColorFiltered(colorFilter: matrix, child: w);
    }
    if (!_prefs.enableEInk &&
        !_prefs.enableGray &&
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
    final accent = Theme.of(context).colorScheme.primary;
    final img = RemoteBinaryImage(
      url: url,
      headers: _imageHeaders,
      fit: fillWidth ? BoxFit.fitWidth : BoxFit.contain,
      width: fillWidth ? double.infinity : null,
      placeholderBuilder: (context) => SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 3),
        ),
      ),
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
    if (_prefs.disableScale) return filtered;
    return InteractiveViewer(minScale: 1, maxScale: 4, child: filtered);
  }

  Widget _buildContent() {
    if (_error != null && _imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isHorizontal) {
      return PageView.builder(
        controller: _pageController,
        reverse: _isRtl,
        physics: _prefs.disableHorizontalPageSnap
            ? const ClampingScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: _imageUrls.length,
        onPageChanged: (i) {
          setState(() => _pageIndex = i);
          _precacheNearby();
          unawaited(_persistProgress());
        },
        itemBuilder: (_, i) =>
            Center(child: _buildImage(_imageUrls[i], fillWidth: true)),
      );
    }

    return ListView.builder(
      controller: _verticalController,
      padding: EdgeInsets.zero,
      itemCount: _imageUrls.length + (_prefs.hideTitle ? 0 : 1),
      itemBuilder: (_, i) {
        if (!_prefs.hideTitle && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              _chapter?.title ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          );
        }
        final imgIndex = _prefs.hideTitle ? i : i - 1;
        return _buildImage(_imageUrls[imgIndex], fillWidth: true);
      },
    );
  }

  /// 对齐 [ReaderInfoBarView]：高 20dp、底边距 10、左右 pad 10；左文案 + 右时钟
  Widget _infoBar(ThemeData theme) {
    final cfg = _prefs.footer;
    if (cfg.hideFooter || _loading || _imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    final buf = StringBuffer();
    final ch = _chapter;
    if (!cfg.hideChapterName) {
      buf.write('${ch?.title ?? ''} ');
    }
    if (!cfg.hidePageNumber) {
      if (!cfg.hidePageNumberLabel) buf.write('页数');
      buf.write('${_pageIndex + 1}/${_imageUrls.length} ');
    }
    if (!cfg.hideChapter) {
      if (!cfg.hideChapterLabel) buf.write('章节');
      buf.write('${_chapterIndex + 1}/${widget.chapters.length} ');
    }
    if (!cfg.hideProgressRatio) {
      if (!cfg.hideProgressRatioLabel) buf.write('总进度');
      final chapterSize = widget.chapters.length;
      final imageCount = _imageUrls.length;
      String percent;
      if (chapterSize == 0 || (imageCount == 0 && _chapterIndex == 0)) {
        percent = '0.0%';
      } else if (imageCount == 0) {
        percent =
            '${((_chapterIndex + 1.0) / chapterSize * 100).toStringAsFixed(1)}%';
      } else {
        var p =
            _chapterIndex * 1.0 / chapterSize +
            1.0 / chapterSize * (_pageIndex + 1) / imageCount;
        percent = '${(p * 100).toStringAsFixed(1)}%';
        if (percent == '100.0%' &&
            (_chapterIndex + 1 != chapterSize ||
                _pageIndex + 1 != imageCount)) {
          percent = '99.9%';
        }
      }
      buf.write(percent);
    }
    final label = buf.toString().trim();
    final alignLeft = cfg.footerOrientation == 0;
    final fg = theme.colorScheme.onSurface.withValues(alpha: 200 / 255);
    final outline = theme.colorScheme.surface.withValues(alpha: 200 / 255);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: IgnorePointer(
        child: SizedBox(
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: alignLeft
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: _OutlinedText(
                      label,
                      fill: fg,
                      stroke: outline,
                      fontSize: 11,
                      maxLines: 1,
                    ),
                  ),
                ),
                _OutlinedText(
                  _clockText,
                  fill: fg,
                  stroke: outline,
                  fontSize: 11,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 加载层 — 对齐 `activity_manga.xml` fl_loading
  Widget _loadingOverlay(ThemeData theme) {
    final show = _loading || (_error != null && _imageUrls.isEmpty);
    if (!show) return const SizedBox.shrink();
    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: _error != null && !_loading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => unawaited(_loadChapter()),
                    child: Text(
                      '重新加载',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '加载中…',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showColorFilterDialog() async {
    var cfg = _prefs.colorFilter;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget slider(
              String title,
              int value,
              ValueChanged<int> onChanged,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title  $value'),
                  Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (v) => setLocal(() => onChanged(v.round())),
                  ),
                ],
              );
            }

            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '滤镜',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    slider(
                      '亮度',
                      cfg.brightness,
                      (v) => cfg = cfg.copyWith(brightness: v),
                    ),
                    slider('R', cfg.r, (v) => cfg = cfg.copyWith(r: v)),
                    slider('G', cfg.g, (v) => cfg = cfg.copyWith(g: v)),
                    slider('B', cfg.b, (v) => cfg = cfg.copyWith(b: v)),
                    slider('A', cfg.a, (v) => cfg = cfg.copyWith(a: v)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      setLocal(() => cfg = const MangaColorFilterConfig()),
                  child: const Text('重置'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await _prefs.setColorFilter(cfg);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEpaperDialog() async {
    var threshold = _prefs.eInkThreshold;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '墨水屏设置',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('阈值  $threshold'),
                  Slider(
                    value: threshold.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    onChanged: (v) => setLocal(() => threshold = v.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await _prefs.setEInk(enabled: true, threshold: threshold);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showFooterConfigDialog() async {
    var cfg = _prefs.footer;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget check(
              String label,
              bool value,
              ValueChanged<bool> onChanged,
            ) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                  ),
                  Text(label),
                ],
              );
            }

            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '页脚配置',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('《章节和文案》隐藏'),
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        check(
                          '《章节.》文案',
                          !cfg.hideChapterLabel,
                          (v) => setLocal(
                            () => cfg = cfg.copyWith(hideChapterLabel: !v),
                          ),
                        ),
                        check(
                          '章节',
                          !cfg.hideChapter,
                          (v) => setLocal(
                            () => cfg = cfg.copyWith(hideChapter: !v),
                          ),
                        ),
                        check(
                          '章节名称',
                          !cfg.hideChapterName,
                          (v) => setLocal(
                            () => cfg = cfg.copyWith(hideChapterName: !v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('《页数和文案》隐藏'),
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        check(
                          '《页数.》文案',
                          !cfg.hidePageNumberLabel,
                          (v) => setLocal(
                            () => cfg = cfg.copyWith(hidePageNumberLabel: !v),
                          ),
                        ),
                        check(
                          '页数',
                          !cfg.hidePageNumber,
                          (v) => setLocal(
                            () => cfg = cfg.copyWith(hidePageNumber: !v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('《总进度和文案》隐藏'),
                    const SizedBox(height: 8),
                    Wrap(
                      children: [
                        check(
                          '《总进度.》文案',
                          !cfg.hideProgressRatioLabel,
                          (v) => setLocal(
                            () =>
                                cfg = cfg.copyWith(hideProgressRatioLabel: !v),
                          ),
                        ),
                        check(
                          '总进度',
                          !cfg.hideProgressRatio,
                          (v) => setLocal(
                            () => cfg = cfg.copyWith(hideProgressRatio: !v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('页脚'),
                    Row(
                      children: [
                        check(
                          '隐藏页脚',
                          cfg.hideFooter,
                          (v) =>
                              setLocal(() => cfg = cfg.copyWith(hideFooter: v)),
                        ),
                        RadioGroup<int>(
                          groupValue: cfg.footerOrientation,
                          onChanged: (v) {
                            if (v != null) {
                              setLocal(
                                () => cfg = cfg.copyWith(footerOrientation: v),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              const Radio<int>(value: 0),
                              const Text('靠左'),
                              const Radio<int>(value: 1),
                              const Text('居中'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await _prefs.setFooter(cfg);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openCatalog() async {
    _runMenuOut();
    final current = _chapter;
    await TocSheet.show(
      context,
      chapters: widget.chapters,
      currentChapter: current?.title,
      currentChapterId: current?.id,
      bookId: widget.book.id,
      onChapterTap: (ch, {int? pageIndex, int? chapterPos}) async {
        final i = widget.chapters.indexWhere((c) => c.id == ch.id);
        if (i < 0 || i == _chapterIndex) return;
        setState(() => _chapterIndex = i);
        await _loadChapter();
      },
    );
  }

  Future<void> _openChangeSource() async {
    _runMenuOut();
    final result = await Navigator.of(context).push<Book>(
      MaterialPageRoute(builder: (_) => ChangeSourcePage(book: widget.book)),
    );
    if (result == null || !mounted) return;
    final chapters = _chapterListPort.currentChapters;
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已换源，但目录为空，请返回详情重试')));
      return;
    }
    final idx = _chapterIndex.clamp(0, chapters.length - 1);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MangaReaderPage(
          book: result,
          chapters: List<Chapter>.from(chapters),
          initialChapterIndex: idx,
          prefs: _prefs,
        ),
      ),
    );
  }

  void _setAutoPage(bool enabled) {
    _autoPageTimer?.cancel();
    _autoPageEnabled = enabled;
    if (!enabled) return;
    final secs = math.max(1, _prefs.autoPageSpeed);
    _autoPageTimer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted || !_autoPageEnabled || _imageUrls.isEmpty) return;
      if (_pageIndex + 1 < _imageUrls.length) {
        _goToPage(_pageIndex + 1);
      } else {
        unawaited(_skipChapter(1));
      }
    });
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'pre_download':
        final n = await _pickNumber(
          title: '预下载',
          value: _prefs.preDownloadNum,
          min: 0,
          max: 50,
        );
        if (n != null) {
          await _prefs.setPreDownloadNum(n);
          _precacheNearby();
          setState(() {});
        }
      case 'disable_scale':
        await _prefs.setDisableScale(!_prefs.disableScale);
        setState(() {});
      case 'disable_click':
        await _prefs.setDisableClickScroll(!_prefs.disableClickScroll);
        setState(() {});
      case 'auto_page':
        final next = !_autoPageEnabled;
        _setAutoPage(next);
        setState(() {});
      case 'auto_page_speed':
        final n = await _pickNumber(
          title: '设置自动翻页速度',
          value: _prefs.autoPageSpeed,
          min: 1,
          max: 20,
        );
        if (n != null) {
          await _prefs.setAutoPageSpeed(n);
          if (_autoPageEnabled) _setAutoPage(true);
          setState(() {});
        }
      case 'horizontal':
        await _prefs.setHorizontalScroll(!_prefs.enableHorizontalScroll);
        setState(() {
          _pageController?.dispose();
          _pageController = _isHorizontal
              ? PageController(initialPage: _pageIndex)
              : null;
        });
      case 'disable_h_snap':
        await _prefs.setDisableHorizontalPageSnap(
          !_prefs.disableHorizontalPageSnap,
        );
        setState(() {});
      case 'disable_anim':
        await _prefs.setDisablePageAnim(!_prefs.disablePageAnim);
        setState(() {});
      case 'footer':
        await _showFooterConfigDialog();
      case 'filter':
        await _showColorFilterDialog();
      case 'hide_title':
        await _prefs.setHideTitle(!_prefs.hideTitle);
        setState(() {});
      case 'eink':
        final next = !_prefs.enableEInk;
        await _prefs.setEInk(enabled: next);
        setState(() {});
        if (next && mounted) await _showEpaperDialog();
      case 'eink_setting':
        await _showEpaperDialog();
      case 'gray':
        await _prefs.setGray(!_prefs.enableGray);
        setState(() {});
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx, v),
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// MangaMenu TitleBar — 对齐 `view_manga_menu.xml` + `menu/book_manga.xml`
  Widget _mangaMenuTop(ThemeData theme) {
    final sourceName = _sourcePresentationPort.sourceNameForBook(widget.book);
    final onSurface = theme.colorScheme.onSurface;
    final menuBg = theme.colorScheme.surfaceContainerHigh;

    return Material(
      color: menuBg,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: onSurface),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // 对齐 MangaMenu: openBookInfoActivity
                      },
                      child: Text(
                        widget.book.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.swap_horiz, color: onSurface),
                    tooltip: '换源',
                    onPressed: () => unawaited(_openChangeSource()),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: onSurface),
                    tooltip: '刷新',
                    onPressed: () {
                      _runMenuOut();
                      unawaited(_loadChapter());
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.menu_book_outlined, color: onSurface),
                    tooltip: '目录',
                    onPressed: () => unawaited(_openCatalog()),
                  ),
                  PopupMenuButton<String>(
                    offset: legadoAppBarPopupOffset(context),
                    icon: Icon(Icons.more_vert, color: onSurface),
                    onSelected: (v) => unawaited(_onMenuSelected(v)),
                    itemBuilder: (_) => [
                      CheckedPopupMenuItem(
                        value: 'disable_scale',
                        checked: _prefs.disableScale,
                        child: const Text('禁用漫画缩放'),
                      ),
                      CheckedPopupMenuItem(
                        value: 'disable_click',
                        checked: _prefs.disableClickScroll,
                        child: const Text('禁用点击翻页'),
                      ),
                      CheckedPopupMenuItem(
                        value: 'auto_page',
                        checked: _autoPageEnabled,
                        child: const Text('开启自动翻页'),
                      ),
                      if (_autoPageEnabled)
                        PopupMenuItem(
                          value: 'auto_page_speed',
                          child: Text('翻页速度 ${_prefs.autoPageSpeed}'),
                        ),
                      CheckedPopupMenuItem(
                        value: 'horizontal',
                        checked: _prefs.enableHorizontalScroll,
                        child: const Text('水平滚动'),
                      ),
                      if (_prefs.enableHorizontalScroll)
                        CheckedPopupMenuItem(
                          value: 'disable_h_snap',
                          checked: _prefs.disableHorizontalPageSnap,
                          child: const Text('禁用水平翻页效果'),
                        ),
                      CheckedPopupMenuItem(
                        value: 'disable_anim',
                        checked: _prefs.disablePageAnim,
                        child: const Text('禁用翻页动画'),
                      ),
                      const PopupMenuItem(value: 'footer', child: Text('页脚配置')),
                      const PopupMenuItem(value: 'filter', child: Text('滤镜')),
                      CheckedPopupMenuItem(
                        value: 'hide_title',
                        checked: _prefs.hideTitle,
                        child: const Text('隐藏漫画列表标题'),
                      ),
                      CheckedPopupMenuItem(
                        value: 'eink',
                        checked: _prefs.enableEInk,
                        child: const Text('墨水屏'),
                      ),
                      if (_prefs.enableEInk)
                        const PopupMenuItem(
                          value: 'eink_setting',
                          child: Text('墨水屏设置'),
                        ),
                      CheckedPopupMenuItem(
                        value: 'gray',
                        checked: _prefs.enableGray,
                        child: const Text('开启图片灰色'),
                      ),
                      PopupMenuItem(
                        value: 'pre_download',
                        child: Text('预下载${_prefs.preDownloadNum}页'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // title_bar_addition
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 1, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chapter?.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: onSurface, fontSize: 13),
                        ),
                        if ((_chapter?.url ?? '').isNotEmpty)
                          Text(
                            _chapter!.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      sourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 11,
                      ),
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

  /// bottom_menu — 对齐 view_manga_menu：上一章 | SeekBar | 下一章
  Widget _mangaMenuBottom(ThemeData theme) {
    final canPrev = _chapterIndex > 0;
    final canNext = _chapterIndex + 1 < widget.chapters.length;
    final maxPage = math.max(0, _imageUrls.length - 1).toDouble();
    final value = (_seeking ? _seekValue : _pageIndex.toDouble()).clamp(
      0.0,
      math.max(maxPage, 0.0),
    );
    final menuBg = theme.colorScheme.surfaceContainerHigh;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: menuBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextButton(
                  onPressed: canPrev ? () => unawaited(_skipChapter(-1)) : null,
                  style: TextButton.styleFrom(
                    foregroundColor: onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: const Text('上一章'),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 25,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      activeTrackColor: theme.colorScheme.primary.withValues(
                        alpha: 0.55,
                      ),
                      inactiveTrackColor: onSurface.withValues(alpha: 0.24),
                      thumbColor: theme.colorScheme.primary,
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextButton(
                  onPressed: canNext ? () => unawaited(_skipChapter(1)) : null,
                  style: TextButton.styleFrom(
                    foregroundColor: onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: const Text('下一章'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mangaMenuOverlay(ThemeData theme) {
    if (!_chromeVisible && _menuAnim.isDismissed) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _menuAnim,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_menuAnim.value);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _runMenuOut,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.001),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, -80 * (1 - t)),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: _mangaMenuTop(theme),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, 80 * (1 - t)),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: _mangaMenuBottom(theme),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapZone,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(),
            if (!_chromeVisible) _infoBar(theme),
            _mangaMenuOverlay(theme),
            _loadingOverlay(theme),
          ],
        ),
      ),
    );
  }
}

/// ReaderInfoBarView 描边文字近似
class _OutlinedText extends StatelessWidget {
  final String text;
  final Color fill;
  final Color stroke;
  final double fontSize;
  final int maxLines;

  const _OutlinedText(
    this.text, {
    required this.fill,
    required this.stroke,
    this.fontSize = 11,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = stroke,
            shadows: const [
              Shadow(
                blurRadius: 2,
                offset: Offset(1, 1),
                color: Colors.black54,
              ),
            ],
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: fontSize, color: fill),
        ),
      ],
    );
  }
}
