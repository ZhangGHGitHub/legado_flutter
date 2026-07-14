import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../model/read_book.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/note_service.dart';
import '../../services/reading_record_service.dart';
import '../../utils/chinese_convert.dart';
import '../book/change_source_page.dart';
import '../book/toc_sheet.dart';
import '../book/book_info_page.dart';
import '../reader/ai_chat_page.dart';
import 'auto_read_panel.dart';
import 'click_action_panel.dart';
import 'more_settings_panel.dart';
import 'reader_settings.dart';
import 'tts_panel.dart';
import '../../widgets/bookplate_overlay.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/reader_selectable_text.dart';

/// 阅读器页面 — Phase F UI-1：chrome 自动隐藏 / 底栏章进度 / 更多菜单
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
  DateTime? _sessionStart;
  int _sessionChars = 0;
  int _lastCountedChapterIndex = -1;

  /// UI-1: 顶/底 chrome 可见性（点击正文切换；进入后短延迟自动收起）
  bool _chromeVisible = true;
  Timer? _autoHideTimer;
  static const _autoHideDelay = Duration(seconds: 3);

  /// 翻页模式切换代数，配合 Key 强制拆掉旧 PageView/ScrollView
  int _modeGeneration = 0;

  /// UI-2: 音量键翻页焦点（桌面/模拟器可用；真机因系统接管可能无效）
  final FocusNode _focusNode = FocusNode();

  /// UI-2: 自动阅读定时翻页
  Timer? _autoReadTimer;
  bool _autoReadRunning = false;

  /// UI-2: 底栏电量真值
  final Battery _battery = Battery();
  int? _batteryLevel;
  Timer? _batteryTimer;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _settings = const ReaderSettings();
    _scrollController = ScrollController();
    _currentIndex = widget.allChapters.indexOf(widget.chapter);
    if (_currentIndex < 0) _currentIndex = 0;
    if (widget.book.currentPageIndex > 0) {
      _pendingTargetPage = widget.book.currentPageIndex;
    }
    _loadContent();
    _scheduleAutoHide();
    _refreshBattery();
    _batteryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshBattery(),
    );
    _applyKeepScreenOn(_settings.keepScreenOn);
    _applySystemUi();
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {
      // 桌面/模拟器可能无电池信息
    }
  }

  void _applyScreenOrientation(ScreenOrientationMode mode) {
    switch (mode) {
      case ScreenOrientationMode.system:
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      case ScreenOrientationMode.portrait:
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      case ScreenOrientationMode.landscape:
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
    }
  }

  Future<void> _applyKeepScreenOn(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {
      // 桌面/部分环境可能无 wakelock 后端
    }
  }

  /// 沉浸式系统栏（对齐 hideStatusBar / hideNavigationBar；菜单可见时短暂恢复）
  void _applySystemUi() {
    final hideStatus = _settings.hideStatusBar && !_chromeVisible;
    final hideNav = _settings.hideNavigationBar && !_chromeVisible;
    if (hideStatus && hideNav) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (hideStatus || hideNav) {
      final overlays = <SystemUiOverlay>[
        if (!hideStatus) SystemUiOverlay.top,
        if (!hideNav) SystemUiOverlay.bottom,
      ];
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: overlays,
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    final darkTheme = _settings.themeName == 'dark';
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness:
            darkTheme ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            darkTheme ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// 排版：简繁 → 段缩进 → 段距（空行）
  String _prepareDisplayText(String raw) {
    var text = ChineseConvert.apply(raw, _settings.chineseConvert.code);
    if (_isEmptyBody ||
        text.startsWith('⚠️') ||
        text.contains('（加载失败') ||
        text == '加载中...') {
      return text;
    }
    final indent = _settings.paragraphIndentText;
    final gapLines = (_settings.paragraphSpacing * 10).round().clamp(0, 20);
    final gap = gapLines > 0 ? '\n' * gapLines : '';
    final paragraphs = text.split('\n');
    final out = StringBuffer();
    for (var i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      if (p.trim().isEmpty) {
        out.writeln();
        continue;
      }
      final body = p.replaceFirst(RegExp(r'^[\s　]+'), '');
      out.write(indent);
      out.write(body);
      if (i < paragraphs.length - 1) {
        out.write('\n');
        if (gap.isNotEmpty) out.write(gap);
      }
    }
    return out.toString();
  }

  String get _displayContent => _prepareDisplayText(_content);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookProvider = context.read<BookProvider>();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _autoReadTimer?.cancel();
    _batteryTimer?.cancel();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    unawaited(_applyKeepScreenOn(false));
    _saveProgress();
    _recordReadingSession();
    _scrollController.dispose();
    _pageController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setAutoReadRunning(bool running) {
    _autoReadTimer?.cancel();
    _autoReadTimer = null;
    setState(() => _autoReadRunning = running);
    if (!running) return;
    final interval = Duration(
      milliseconds: (_settings.autoReadIntervalSec * 1000).round(),
    );
    _autoReadTimer = Timer.periodic(interval, (_) {
      if (!mounted || !_autoReadRunning) return;
      final atLastPage = _settings.pageMode == 'slide' &&
          _pages.isNotEmpty &&
          _pageIndex >= _pages.length - 1 &&
          _currentIndex >= widget.allChapters.length - 1;
      final atLastChapterScroll = _settings.pageMode != 'slide' &&
          _currentIndex >= widget.allChapters.length - 1;
      if (atLastPage || atLastChapterScroll) {
        _setAutoReadRunning(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已到全书末尾，自动阅读已停止')),
        );
        return;
      }
      _nextPage();
    });
  }

  void _restartAutoReadIfNeeded() {
    if (_autoReadRunning) _setAutoReadRunning(true);
  }

  void _runClickAction(ClickZoneAction action) {
    switch (action) {
      case ClickZoneAction.prevPage:
        _prevPage();
      case ClickZoneAction.nextPage:
        _nextPage();
      case ClickZoneAction.toggleMenu:
        _toggleChrome();
      case ClickZoneAction.none:
        break;
    }
  }

  /// 上/中/下点击热区（覆盖正文；选择文本仍由下层处理，translucent）
  Widget _buildClickZones() {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _runClickAction(_settings.clickTop),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _runClickAction(_settings.clickMiddle),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _runClickAction(_settings.clickBottom),
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }

  void _openTtsPanel() {
    _autoHideTimer?.cancel();
    final text = _pages.isNotEmpty
        ? _pages[_pageIndex.clamp(0, _pages.length - 1)]
        : _content;
    TtsPanel.show(
      context,
      sampleText: text,
      onPrevChapter: () {
        if (_currentIndex > 0) _goToChapter(_currentIndex - 1);
      },
      onNextChapter: () {
        if (_currentIndex < widget.allChapters.length - 1) {
          _goToChapter(_currentIndex + 1);
        }
      },
      onPrevPage: _prevPage,
      onNextPage: _nextPage,
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  void _openAutoReadPanel() {
    _autoHideTimer?.cancel();
    AutoReadPanel.show(
      context,
      settings: _settings,
      isRunning: _autoReadRunning,
      onChanged: (s) {
        _onSettingsChanged(s);
        _restartAutoReadIfNeeded();
      },
      onRunningChanged: _setAutoReadRunning,
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  void _openMoreSettingsPanel() {
    _autoHideTimer?.cancel();
    MoreSettingsPanel.show(
      context,
      settings: _settings,
      onChanged: _onSettingsChanged,
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  void _openClickZonePanel() {
    _autoHideTimer?.cancel();
    ClickActionPanel.show(
      context,
      settings: _settings,
      onChanged: _onSettingsChanged,
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    if (!_chromeVisible) return;
    _autoHideTimer = Timer(_autoHideDelay, () {
      if (mounted && _chromeVisible) {
        setState(() => _chromeVisible = false);
        _applySystemUi();
      }
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    _applySystemUi();
    if (_chromeVisible) {
      _scheduleAutoHide();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  void _keepChromeAlive() {
    if (!_chromeVisible) {
      setState(() => _chromeVisible = true);
      _applySystemUi();
    }
    _scheduleAutoHide();
  }

  void _countChapterChars(String content) {
    if (content.startsWith('⚠️') || content.contains('未找到匹配的书源')) {
      return;
    }
    if (_currentIndex == _lastCountedChapterIndex) return;
    _sessionChars += content.length;
    _lastCountedChapterIndex = _currentIndex;
  }

  void _recordReadingSession() {
    if (_sessionStart == null || _sessionChars <= 0) return;
    final duration = DateTime.now().difference(_sessionStart!).inSeconds;
    if (duration <= 0) return;
    ReadingRecordService.recordReading(
      bookId: widget.book.id,
      bookName: widget.book.name,
      chars: _sessionChars,
      durationSeconds: duration,
    );
  }

  Future<void> _openNoteEditor(String selectedText) async {
    if (selectedText.trim().isEmpty) return;
    final chapter = widget.allChapters[_currentIndex];
    await showNoteEditorSheet(
      context,
      book: widget.book,
      chapterTitle: chapter.title,
      selectedText: selectedText.trim(),
      position: _currentIndex,
    );
  }

  TextStyle _readerTextStyle(Color color) {
    // 勿用 inherit:false（须同时提供 textBaseline，否则红屏）：
    // inherit false style must supply fontSize and textBaseline
    return TextStyle(
      fontSize: _settings.fontSize,
      height: _settings.lineHeight,
      color: color,
      fontFamily: _settings.fontFamily.isEmpty ? null : _settings.fontFamily,
      fontWeight: _settings.fontWeight.flutterWeight,
      letterSpacing: _settings.letterSpacing * _settings.fontSize,
    );
  }

  TextAlign get _readerTextAlign =>
      _settings.textFullJustify ? TextAlign.justify : TextAlign.start;

  bool get _isEmptyBody => ReadBook.isEmptyContentPlaceholder(_content);

  /// 书源展示：优先书源名，其次书籍来源 URL
  String get _sourceSubtitle {
    final source = context.read<SourceProvider>().findSourceForBook(widget.book);
    if (source != null && source.bookSourceName.isNotEmpty) {
      return source.bookSourceName;
    }
    if (widget.book.bookSourceUrl.isNotEmpty) return widget.book.bookSourceUrl;
    if (widget.book.sourceUrl.isNotEmpty) return widget.book.sourceUrl;
    return '';
  }

  Future<void> _loadContent({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final chapter = widget.allChapters[_currentIndex];
      final bookProvider = context.read<BookProvider>();
      final source = context.read<SourceProvider>().findSourceForBook(
        widget.book,
      );
      String content;
      if (source != null) {
        if (forceRefresh) {
          await ReadBook.instance.invalidateChapterCache(
            chapter.id,
            bookId: widget.book.id,
          );
        }
        content = await bookProvider.loadChapterContentCached(
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _settings.pageMode == 'slide') {
              _splitIntoPages();
            }
          });
        });
        final ok = !ReadBook.isEmptyContentPlaceholder(content) &&
            !content.contains('（加载失败') &&
            !content.startsWith('⚠️');
        if (ok) {
          bookProvider.markChapterDownloaded(chapter.id);
        }
        _countChapterChars(content);
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

  /// 将正文按屏幕高度拆分为独立页面（仅 slide 模式）
  void _splitIntoPages() {
    if (_content.isEmpty || !mounted) return;
    if (_settings.pageMode != 'slide') return;
    // 空章占位不进 PageView，由 _buildBodyText 展示刷新引导
    if (ReadBook.isEmptyContentPlaceholder(_content)) {
      final dying = _pageController;
      _pageController = null;
      setState(() {
        _pages = [];
        _pageIndex = 0;
      });
      if (dying != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => dying.dispose());
      }
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // 布局尚未就绪时再试一次（模式切换后常见）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _settings.pageMode != 'slide') return;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) _splitIntoPages();
      });
      return;
    }

    final pad = MediaQuery.of(context).padding;
    final edgePadL = _settings.expandIntoCutout ? 0.0 : pad.left;
    final edgePadR = _settings.expandIntoCutout ? 0.0 : pad.right;
    final edgePadT = _settings.expandIntoCutout ? 0.0 : pad.top;
    final edgePadB = _settings.expandIntoCutout ? 0.0 : pad.bottom;
    final display = _displayContent;
    final hPad = _settings.paddingHorizontal * 2;
    final pageWidth =
        renderBox.size.width - hPad - edgePadL - edgePadR;
    // chrome 以 overlay 叠在正文上，分页按「无顶/底栏」可视高度估算
    final chapterTitleHeight = _settings.fontSize + 36.0;
    final pageHeight =
        renderBox.size.height -
        edgePadT -
        edgePadB -
        chapterTitleHeight -
        48 -
        _settings.paddingVertical * 2;

    final result = <String>[];
    var totalHeight = 0.0;

    if (pageWidth <= 0 || pageHeight <= 0) {
      result.add(display);
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: display,
          style: TextStyle(
            fontSize: _settings.fontSize,
            height: _settings.lineHeight,
            fontFamily:
                _settings.fontFamily.isEmpty ? null : _settings.fontFamily,
            fontWeight: _settings.fontWeight.flutterWeight,
            letterSpacing: _settings.letterSpacing * _settings.fontSize,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: _readerTextAlign,
      );
      tp.layout(maxWidth: pageWidth);
      totalHeight = tp.height;

      if (totalHeight <= pageHeight) {
        result.add(display);
      } else {
        int startOffset = 0;
        int pageNum = 1;
        while (startOffset < display.length) {
          final targetY = pageNum * pageHeight;
          if (targetY >= totalHeight) {
            result.add(display.substring(startOffset));
            break;
          }
          final pos = tp.getPositionForOffset(Offset(0.0, targetY));
          if (pos.offset <= startOffset) {
            result.add(display.substring(startOffset));
            break;
          }
          result.add(display.substring(startOffset, pos.offset));
          startOffset = pos.offset;
          pageNum++;
        }
      }
    }

    if (result.isEmpty) result.add(display);

    final targetPage = _pendingTargetPage ?? 0;
    final clampedPage = targetPage < 0
        ? result.length - 1
        : (targetPage >= result.length ? 0 : targetPage);

    // 先换新 controller，旧的延后 dispose，避免 PageView 仍挂着已 dispose 的实例
    final oldController = _pageController;
    _pageController = PageController(initialPage: clampedPage);
    setState(() {
      _pages = result;
      _pageIndex = clampedPage;
      _pendingTargetPage = null;
    });
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }
    debugPrint(
      '📖 分页完成: ${result.length} 页 (目标=$clampedPage, 总高度=$totalHeight, 页高=$pageHeight)',
    );
  }

  /// 设置面板变更：翻页模式切换时先卸树，再 post-frame dispose 控制器
  void _onSettingsChanged(ReaderSettings newSettings) {
    if (newSettings.screenOrientation != _settings.screenOrientation) {
      _applyScreenOrientation(newSettings.screenOrientation);
    }
    if (newSettings.keepScreenOn != _settings.keepScreenOn) {
      _applyKeepScreenOn(newSettings.keepScreenOn);
    }
    final immersionChanged =
        newSettings.hideStatusBar != _settings.hideStatusBar ||
            newSettings.hideNavigationBar != _settings.hideNavigationBar ||
            newSettings.themeName != _settings.themeName;
    if (newSettings.showBattery && _batteryLevel == null) {
      _refreshBattery();
    }
    final oldMode = _settings.pageMode;
    final newMode = newSettings.pageMode;
    final modeChanged = oldMode != newMode;
    final needRepaginate = newMode == 'slide' &&
        !_isLoading &&
        _content.isNotEmpty &&
        (modeChanged ||
            newSettings.fontSize != _settings.fontSize ||
            newSettings.lineHeight != _settings.lineHeight ||
            newSettings.fontFamily != _settings.fontFamily ||
            newSettings.fontWeight != _settings.fontWeight ||
            newSettings.letterSpacing != _settings.letterSpacing ||
            newSettings.paragraphSpacing != _settings.paragraphSpacing ||
            newSettings.paragraphIndent != _settings.paragraphIndent ||
            newSettings.chineseConvert != _settings.chineseConvert ||
            newSettings.paddingHorizontal != _settings.paddingHorizontal ||
            newSettings.paddingVertical != _settings.paddingVertical ||
            newSettings.expandIntoCutout != _settings.expandIntoCutout ||
            newSettings.textFullJustify != _settings.textFullJustify);

    if (modeChanged) {
      // Phase 1：摘掉 PageController 引用并清空分页，确保本帧不再挂 PageView
      final dyingPage = _pageController;
      _pageController = null;
      setState(() {
        _settings = newSettings;
        _pages = [];
        _pageIndex = 0;
        _modeGeneration++;
      });
      if (immersionChanged) _applySystemUi();

      // Phase 2：上一帧视图已 detach，再 dispose；slide 再重建分页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dyingPage?.dispose();
        if (!mounted) return;
        if (newMode == 'slide' && needRepaginate) {
          _splitIntoPages();
        }
      });
      return;
    }

    setState(() => _settings = newSettings);
    if (immersionChanged) _applySystemUi();
    if (needRepaginate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _settings.pageMode == 'slide') _splitIntoPages();
      });
    }
  }

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
    final dyingPage = _pageController;
    _pageController = null;
    setState(() {
      _pages = [];
      _pageIndex = 0;
      _currentIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dyingPage?.dispose();
    });
    _loadContent();
    _keepChromeAlive();
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

  Future<void> _showTocSheet() async {
    final provider = context.read<BookProvider>();
    // 对齐 Legado：目录秒开，不在此等待联网 / 扫盘
    final chapters = provider.currentChapters.isNotEmpty &&
            provider.currentChapters.first.bookId == widget.book.id
        ? provider.currentChapters
        : widget.allChapters;
    if (!mounted) return;
    final current = widget.allChapters[_currentIndex];
    await TocSheet.show(
      context,
      chapters: chapters,
      currentChapter: current.title,
      currentChapterId: current.id,
      bookId: widget.book.id,
      onChapterTap: (chapter) {
        final idx = widget.allChapters.indexWhere((c) => c.id == chapter.id);
        if (idx >= 0) {
          _goToChapter(idx);
        } else {
          final byUrl =
              widget.allChapters.indexWhere((c) => c.url == chapter.url);
          if (byUrl >= 0) _goToChapter(byUrl);
        }
      },
    );
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature（开发中，后续版本接入）')),
    );
  }

  Future<void> _refreshChapter() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在刷新本章…'), duration: Duration(seconds: 1)),
    );
    await _loadContent(forceRefresh: true);
  }

  Future<void> _addBookmark() async {
    if (!NoteService.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('引擎未就绪，无法添加书签')),
      );
      return;
    }
    final chapter = widget.allChapters[_currentIndex];
    final snippet = _settings.pageMode == 'slide' && _pages.isNotEmpty
        ? _pages[_pageIndex].trim()
        : _content.trim();
    final preview = snippet.length > 80 ? '${snippet.substring(0, 80)}…' : snippet;
    final pageHint = _settings.pageMode == 'slide' && _pages.isNotEmpty
        ? '第${_pageIndex + 1}/${_pages.length}页'
        : '滚动位置';
    NoteService.save(
      id: const Uuid().v4(),
      bookId: widget.book.id,
      chapterTitle: chapter.title,
      selectedText: preview.isEmpty ? chapter.title : preview,
      noteContent: '书签 · $pageHint',
      position: _currentIndex,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加书签')),
    );
  }

  Future<void> _copyContent() async {
    final text = _settings.pageMode == 'slide' && _pages.isNotEmpty
        ? _pages[_pageIndex]
        : _content;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制本章/本页内容')),
    );
  }

  void _openChangeSource() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChangeSourcePage(book: widget.book)),
    );
  }

  void _openBookInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookInfoPage(book: widget.book)),
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'toc':
        _showTocSheet();
      case 'settings':
        _showSettingsPanel();
      case 'ai':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiChatPage(isStandalone: false),
          ),
        );
      case 'change_source':
        _openChangeSource();
      case 'refresh':
        _refreshChapter();
      case 'bookmark':
        _addBookmark();
      case 'copy':
        _copyContent();
      case 'book_info':
        _openBookInfo();
      case 'cache':
        _showNotImplemented('离线缓存');
      case 'page_anim':
        _showNotImplemented('翻页动画(本书)');
      case 'cloud_progress':
        _showNotImplemented('拉取云端进度');
      case 'reverse':
        _showNotImplemented('反转内容');
      case 'replace':
        _showNotImplemented('替换净化开关');
      case 'resegment':
        _showNotImplemented('重新分段');
      case 'update_toc':
        _showNotImplemented('更新目录');
      case 'tts':
        _openTtsPanel();
      case 'auto_read':
        _openAutoReadPanel();
      case 'click_zone':
        _openClickZonePanel();
      case 'page_key':
      case 'more_settings':
        _openMoreSettingsPanel();
    }
  }

  List<PopupMenuEntry<String>> _menuItems() {
    PopupMenuItem<String> item(String value, IconData icon, String label) {
      return PopupMenuItem(
        value: value,
        child: ListTile(
          leading: Icon(icon, size: 20),
          title: Text(label, style: const TextStyle(fontSize: 14)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    }

    return [
      item('change_source', Icons.swap_horiz, '换源'),
      item('refresh', Icons.refresh, '刷新'),
      item('cache', Icons.download_outlined, '离线缓存'),
      const PopupMenuDivider(),
      item('toc', Icons.list_alt, '目录'),
      item('bookmark', Icons.bookmark_add_outlined, '书签'),
      item('copy', Icons.copy_outlined, '拷贝内容'),
      item('settings', Icons.settings, '阅读设置'),
      item('ai', Icons.smart_toy_outlined, 'AI 助手'),
      const PopupMenuDivider(),
      item('page_anim', Icons.animation, '翻页动画(本书)'),
      item('cloud_progress', Icons.cloud_download_outlined, '拉取云端进度'),
      item('reverse', Icons.swap_vert, '反转内容'),
      item('replace', Icons.find_replace, '替换净化开关'),
      item('resegment', Icons.notes, '重新分段'),
      item('update_toc', Icons.toc, '更新目录'),
      item('book_info', Icons.info_outline, '书籍信息'),
      const PopupMenuDivider(),
      item('tts', Icons.record_voice_over_outlined, '朗读'),
      item('auto_read', Icons.speed, '自动阅读'),
      item('click_zone', Icons.grid_on, '点击区域设置'),
      item('more_settings', Icons.tune, '更多设置'),
      item('page_key', Icons.keyboard, '自定义翻页键'),
    ];
  }

  /// 始终挂在树上，用透明度显隐；桌面端整页已 ExcludeSemantics，
  /// 这里再包一层避免 chrome 切显隐时额外撕语义节点。
  Widget _chromeLayer({required Widget child}) {
    return ExcludeSemantics(
      child: IgnorePointer(
        ignoring: !_chromeVisible,
        child: Opacity(
          opacity: _chromeVisible ? 1 : 0,
          child: child,
        ),
      ),
    );
  }

  Widget _buildTopChrome(ReaderTheme theme) {
    return Material(
      elevation: 4,
      color: theme.appBar.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: IconTheme(
          data: IconThemeData(color: theme.text),
          child: DefaultTextStyle(
            style: TextStyle(color: theme.text, fontSize: 15),
            child: SizedBox(
              height: kToolbarHeight,
              child: NavigationToolbar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _saveProgress();
                    Navigator.pop(context);
                  },
                ),
                middle: Text(
                  widget.book.name,
                  style: TextStyle(fontSize: 15, color: theme.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.list_alt),
                      onPressed: _showTocSheet,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: _onMenuSelected,
                      itemBuilder: (_) => _menuItems(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 章头：章节名 + 书源（始终显示于正文区顶部）
  Widget _buildChapterHeader(Chapter chapter, ReaderTheme theme) {
    final source = _sourceSubtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            chapter.title,
            style: TextStyle(
              fontSize: _settings.fontSize + 2,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                source,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.text.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  String _formatClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _pageInfoLabel() {
    if (_settings.pageMode == 'slide' && _pages.isNotEmpty) {
      return '${_pageIndex + 1}/${_pages.length}页';
    }
    return '${_currentIndex + 1}/${widget.allChapters.length}章';
  }

  String _bookProgressLabel() {
    final pct = ((_currentIndex + 1) / widget.allChapters.length * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    return '$pct%';
  }

  /// UI-1 底栏：前/后章 + 本章进度滑块 + 页码/时间信息
  Widget _buildBottomChrome(ReaderTheme theme) {
    final hasPages = _settings.pageMode == 'slide' && _pages.length > 1;
    final sliderMax = hasPages
        ? (_pages.length - 1).toDouble()
        : (widget.allChapters.length > 1
              ? (widget.allChapters.length - 1).toDouble()
              : 1.0);
    final double sliderValue = hasPages
        ? _pageIndex.toDouble().clamp(0.0, sliderMax).toDouble()
        : _currentIndex.toDouble().clamp(0.0, sliderMax).toDouble();

    return Material(
      elevation: 8,
      color: theme.appBar.withValues(alpha: 0.97),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 信息区：页码 · 全书进度 · 时间 · 电量（UI-2 开关）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _settings.showPageInfo
                            ? '${widget.allChapters[_currentIndex].title} · ${_pageInfoLabel()}'
                            : widget.allChapters[_currentIndex].title,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.text.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      [
                        _bookProgressLabel(),
                        if (_settings.showTime) _formatClock(),
                        if (_settings.showBattery)
                          _batteryLevel != null
                              ? '电量$_batteryLevel%'
                              : '电量--',
                      ].join('  '),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.text.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0
                        ? () => _goToChapter(_currentIndex - 1)
                        : null,
                    icon: Icon(
                      Icons.skip_previous,
                      color: theme.text.withValues(
                        alpha: _currentIndex > 0 ? 0.85 : 0.3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: theme.progress,
                        inactiveTrackColor: theme.text.withValues(alpha: 0.12),
                        thumbColor: theme.progress,
                      ),
                      child: Slider(
                        min: 0,
                        max: sliderMax,
                        divisions: sliderMax.toInt() > 0
                            ? sliderMax.toInt()
                            : null,
                        value: sliderValue,
                        onChanged: (v) {
                          _keepChromeAlive();
                          if (hasPages) {
                            final target = v.round();
                            if (target != _pageIndex &&
                                _pageController != null) {
                              _pageController!.jumpToPage(target);
                              setState(() => _pageIndex = target);
                            }
                          } else {
                            final target = v.round();
                            if (target != _currentIndex) {
                              _goToChapter(target);
                            }
                          }
                        },
                        onChangeStart: (_) => _autoHideTimer?.cancel(),
                        onChangeEnd: (_) => _scheduleAutoHide(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _currentIndex < widget.allChapters.length - 1
                        ? () => _goToChapter(_currentIndex + 1)
                        : null,
                    icon: Icon(
                      Icons.skip_next,
                      color: theme.text.withValues(
                        alpha:
                            _currentIndex < widget.allChapters.length - 1
                            ? 0.85
                            : 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              // 快捷入口行
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chromeAction(
                      theme,
                      Icons.list_alt,
                      '目录',
                      _showTocSheet,
                    ),
                    _chromeAction(
                      theme,
                      Icons.swap_horiz,
                      '换源',
                      _openChangeSource,
                    ),
                    _chromeAction(
                      theme,
                      Icons.bookmark_add_outlined,
                      '书签',
                      _addBookmark,
                    ),
                    _chromeAction(
                      theme,
                      Icons.settings,
                      '设置',
                      _showSettingsPanel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chromeAction(
    ReaderTheme theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        _keepChromeAlive();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.text.withValues(alpha: 0.8)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.text.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    _autoHideTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final panel = ReaderSettingsPanel(
          settings: _settings,
          onChanged: _onSettingsChanged,
          onOpenTts: _openTtsPanel,
          onOpenAutoRead: _openAutoReadPanel,
          onOpenClickZone: _openClickZonePanel,
          onOpenMoreSettings: _openMoreSettingsPanel,
        );
        // 设置面板是独立路由，须单独 ExcludeSemantics，否则仍会撞 AXTree
        final isDesktop = switch (defaultTargetPlatform) {
          TargetPlatform.windows ||
          TargetPlatform.linux ||
          TargetPlatform.macOS =>
            true,
          _ => false,
        };
        return isDesktop ? ExcludeSemantics(child: panel) : panel;
      },
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  ReaderTheme get _currentTheme =>
      ReaderTheme.themes[_settings.themeName] ?? ReaderTheme.themes['paper']!;

  @override
  Widget build(BuildContext context) {
    final chapter = widget.allChapters[_currentIndex];
    final theme = _currentTheme;

    // Key 强制按模式+代数整树重建，避免 PageView/ScrollView 元素复用导致控制器双挂
    Widget page = KeyedSubtree(
      key: ValueKey('reader-mode-${_settings.pageMode}-$_modeGeneration'),
      child: _settings.pageMode == 'scroll'
          ? _buildScrollMode(chapter, theme)
          : _buildSlideMode(chapter, theme),
    );

    // 整页排除语义：压制 Windows accessibility_bridge
    // Failed to update ui::AXTree … will not be in the tree（引擎已知缺陷）
    final isDesktop = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
    if (isDesktop) {
      page = ExcludeSemantics(child: page);
    }

    // UI-2：手动阅读亮度（黑遮罩叠在正文之上，不影响系统亮度权限）
    if (!_settings.brightnessFollowSystem) {
      final dim = (1.0 - _settings.brightness.clamp(0.15, 1.0));
      if (dim > 0.01) {
        page = Stack(
          fit: StackFit.expand,
          children: [
            page,
            IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: dim * 0.85),
              ),
            ),
          ],
        );
      }
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onReaderKey,
      child: page,
    );
  }

  /// 正文内容：优先 PageView；否则可滚动全文。空章占位给出显式提示+刷新。
  Widget _buildBodyText(ReaderTheme theme, {required bool paged}) {
    if (_isEmptyBody && !_isLoading) {
      return GestureDetector(
        onTap: _toggleChrome,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 40,
                  color: theme.text.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 12),
                Text(
                  '本章暂无正文',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.text.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '可能是书源规则未匹配或缓存了空结果，可点刷新重试',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.text.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _refreshChapter,
                  child: const Text('刷新本章'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (paged && _pages.isNotEmpty && _pageController != null) {
      return Stack(
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
                  primary: false,
                  padding: EdgeInsets.symmetric(
                    horizontal: _settings.paddingHorizontal,
                    vertical: _settings.paddingVertical,
                  ),
                  child: ReaderSelectableText(
                    text: _pages[index],
                    style: _readerTextStyle(theme.text),
                    textAlign: _readerTextAlign,
                    onWriteNote: _openNoteEditor,
                  ),
                ),
              );
            },
          ),
          Positioned.fill(child: _buildClickZones()),
        ],
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          primary: false,
          padding: EdgeInsets.symmetric(
            horizontal: _settings.paddingHorizontal,
            vertical: _settings.paddingVertical,
          ),
          child: ReaderSelectableText(
            text: _displayContent,
            style: _readerTextStyle(theme.text),
            textAlign: _readerTextAlign,
            onWriteNote: _openNoteEditor,
          ),
        ),
        Positioned.fill(child: _buildClickZones()),
      ],
    );
  }

  /// 滑动翻页模式
  Widget _buildSlideMode(Chapter chapter, ReaderTheme theme) {
    final cutout = _settings.expandIntoCutout;
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          SafeArea(
            top: !cutout,
            bottom: !cutout,
            left: !cutout,
            right: !cutout,
            child: Column(
              children: [
                if (_isLoading && _content != '加载中...')
                  LinearProgressIndicator(
                    backgroundColor: theme.text.withValues(alpha: 0.1),
                    color: theme.progress,
                    minHeight: 2,
                  ),
                _buildChapterHeader(chapter, theme),
                if (!_isLoading && _content != '加载中...' && !_isEmptyBody)
                  BookplateOverlay(
                    book: widget.book,
                    currentChapterIndex: _currentIndex,
                    totalChapters: widget.allChapters.length,
                    textColor: theme.text,
                    isHeader: true,
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
                      : _buildBodyText(theme, paged: true),
                ),
                if (!_isLoading && _content != '加载中...' && !_isEmptyBody)
                  BookplateOverlay(
                    book: widget.book,
                    currentChapterIndex: _currentIndex,
                    totalChapters: widget.allChapters.length,
                    textColor: theme.text,
                    isHeader: false,
                  ),
              ],
            ),
          ),
          if (_autoReadRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 12,
              child: _autoReadBadge(theme),
            ),
          // 顶栏 overlay（始终挂树，避免 AXTree remount）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _chromeLayer(child: _buildTopChrome(theme)),
          ),
          // 底栏 overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _chromeLayer(child: _buildBottomChrome(theme)),
          ),
        ],
      ),
    );
  }

  void _prevPage() {
    if (_settings.pageMode == 'slide' &&
        _pageController != null &&
        _pages.isNotEmpty) {
      if (_pageIndex > 0) {
        _pageController!.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else if (_currentIndex > 0) {
        _pendingTargetPage = -1;
        _goToChapter(_currentIndex - 1);
      }
      return;
    }
    if (_currentIndex > 0) _goToChapter(_currentIndex - 1);
  }

  void _nextPage() {
    if (_settings.pageMode == 'slide' &&
        _pageController != null &&
        _pages.isNotEmpty) {
      if (_pageIndex < _pages.length - 1) {
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else if (_currentIndex < widget.allChapters.length - 1) {
        _pendingTargetPage = 0;
        _goToChapter(_currentIndex + 1);
      }
      return;
    }
    if (_currentIndex < widget.allChapters.length - 1) {
      _goToChapter(_currentIndex + 1);
    }
  }

  KeyEventResult _onReaderKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final keyId = key.keyId.toString();

    if (_settings.customPrevPageKey != null &&
        keyId == _settings.customPrevPageKey) {
      _prevPage();
      return KeyEventResult.handled;
    }
    if (_settings.customNextPageKey != null &&
        keyId == _settings.customNextPageKey) {
      _nextPage();
      return KeyEventResult.handled;
    }

    if (_settings.bluetoothPageKey) {
      if (key == LogicalKeyboardKey.pageUp ||
          key == LogicalKeyboardKey.mediaTrackPrevious) {
        _prevPage();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.pageDown ||
          key == LogicalKeyboardKey.mediaTrackNext) {
        _nextPage();
        return KeyEventResult.handled;
      }
    }

    if (_settings.volumeKeyTurnPage) {
      if (key == LogicalKeyboardKey.audioVolumeUp) {
        _prevPage();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.audioVolumeDown) {
        _nextPage();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// 滚动翻页模式
  Widget _buildScrollMode(Chapter chapter, ReaderTheme theme) {
    final cutout = _settings.expandIntoCutout;
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          SafeArea(
            top: !cutout,
            bottom: !cutout,
            left: !cutout,
            right: !cutout,
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
                : _isEmptyBody
                ? _buildBodyText(theme, paged: false)
                : Stack(
                    children: [
                      // 不用 AnimatedSwitcher：过渡时新旧 ScrollView 会同时挂上
                      // 同一个 _scrollController，抛出 dual ScrollPosition 异常
                      NotificationListener<ScrollNotification>(
                        key: ValueKey('scroll_$_currentIndex'),
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification) {
                            final pixels =
                                _scrollController.position.pixels;
                            final maxExt =
                                _scrollController.position.maxScrollExtent;
                            if (pixels >= maxExt - 100) {
                              if (_currentIndex <
                                  widget.allChapters.length - 1) {
                                _goToChapter(_currentIndex + 1);
                              }
                            }
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          padding: EdgeInsets.symmetric(
                            horizontal: _settings.paddingHorizontal,
                            vertical: _settings.paddingVertical > 0
                                ? _settings.paddingVertical + 8
                                : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildChapterHeader(chapter, theme),
                              BookplateOverlay(
                                book: widget.book,
                                currentChapterIndex: _currentIndex,
                                totalChapters: widget.allChapters.length,
                                textColor: theme.text,
                                isHeader: true,
                              ),
                              ReaderSelectableText(
                                text: _displayContent,
                                style: _readerTextStyle(theme.text),
                                textAlign: _readerTextAlign,
                                onWriteNote: _openNoteEditor,
                              ),
                              const SizedBox(height: 16),
                              BookplateOverlay(
                                book: widget.book,
                                currentChapterIndex: _currentIndex,
                                totalChapters: widget.allChapters.length,
                                textColor: theme.text,
                                isHeader: false,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(child: _buildClickZones()),
                    ],
                  ),
          ),
          if (_autoReadRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 12,
              child: _autoReadBadge(theme),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _chromeLayer(child: _buildTopChrome(theme)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _chromeLayer(child: _buildBottomChrome(theme)),
          ),
        ],
      ),
    );
  }

  Widget _autoReadBadge(ReaderTheme theme) {
    return Material(
      color: theme.appBar.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _setAutoReadRunning(false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed, size: 16, color: theme.text),
              const SizedBox(width: 4),
              Text(
                '自动 ${_settings.autoReadIntervalSec.toStringAsFixed(1)}s · 点停',
                style: TextStyle(fontSize: 11, color: theme.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
