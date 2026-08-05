import 'dart:async';
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../application/reader/simulated_reading_prefs_port.dart';
import '../../application/reader/read_style_prefs_port.dart';
import '../../application/reader/read_book_config_prefs_port.dart';
import '../../application/reader/reader_font_port.dart';
import '../../application/reader/reader_session_prefs_port.dart';
import '../../application/reader/reader_selection_port.dart';
import '../../application/reader/reader_content_refetch_port.dart';
import '../../application/reader/reader_bookmark_readiness_port.dart';
import '../../application/reader/reader_progress_sync_port.dart';
import '../../application/reader/reader_progress_port.dart';
import '../../application/reader/reader_chapter_refresh_port.dart';
import '../../application/reader/reader_chapter_list_port.dart';
import '../../application/reader/reader_source_access_port.dart';
import '../../application/reader/reader_chapter_cache_status_port.dart';
import '../../application/reader/reader_simulated_reading_port.dart';
import '../../application/reader/reader_image_cache_port.dart';
import '../../application/reader/reader_image_headers_port.dart';
import '../../application/reader/reader_source_presentation_port.dart';
import '../../application/reader/book_reader_prefs_port.dart';
import '../../application/reader/reader_chapter_content_port.dart';
import '../../application/reader/reading_session_tracker.dart';
import '../../application/reader/tts_port.dart';
import '../../domain/ports/chapter_content_cache_port.dart';
import '../../domain/ports/reading_record_port.dart';
import '../../application/cache/cache_book_download_port.dart';
import '../../application/reader/reading_position_mapper.dart';
import '../../application/reader/book_progress_factory.dart';
import '../../application/preferences/click_action_prefs_port.dart';
import '../../domain/reader/book_progress.dart';
import '../../model/read_book.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../../providers/book_provider.dart';
import '../../utils/chinese_convert.dart';
import '../../features/book/change_source_page.dart';
import '../../features/book/toc_sheet.dart';
import '../../features/book/book_info_page.dart';
import '../cache/download_choice_dialog.dart';
import '../cache/download_helpers.dart';
import 'ai_chat_page.dart';
import '../../help/bookmark_hint.dart';
import 'auto_read_panel.dart';
import 'click_action_panel.dart';
import 'click_region_tip_overlay.dart';
import 'content_edit_dialog.dart';
import 'more_settings_panel.dart';
import 'reader_settings.dart';
import 'reader_paginator.dart';
import 'reader_markup.dart';
import 'search_content_page.dart';
import 'search_content_result.dart';
import 'simulated_reading_dialog.dart';
import 'tts_panel.dart';
import 'turn/page_direction.dart';
import 'turn/reader_turn_view.dart';
import 'audio_play_page.dart';
import 'manga_reader_page.dart';
import '../../widgets/bookplate_overlay.dart';
import '../../widgets/bookmark_editor_sheet.dart';
import '../../widgets/dict_lookup_sheet.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/reader_selectable_text.dart';

/// 阅读器页面 — Phase F UI-1：chrome 自动隐藏 / 底栏章进度 / 更多菜单
class ReaderPage extends StatefulWidget {
  final Book book;
  final Chapter chapter;
  final List<Chapter> allChapters;

  /// 打开时跳转到的页索引（0-based）；书签旧数据 fallback。
  final int? initialPageIndex;

  /// 打开时跳转到的章内字符偏移（对齐 Jingshiro chapterPos）；优先于 [initialPageIndex]。
  final int? initialChapterPos;

  /// 单本书阅读配置端口；未注入时使用旧存储服务的适配器。
  final BookReaderPrefsPort? prefs;

  /// 全局阅读配置端口；未注入时从组合根读取。
  final ReadBookConfigPrefsPort? configPrefs;

  /// 正文读取端口；未注入时从组合根读取。
  final ReaderChapterContentPort? contentPort;

  /// 图片请求头端口；未注入时从组合根读取。
  final ReaderImageHeadersPort? imageHeadersPort;

  /// 顶栏书源展示端口；未注入时从组合根读取。
  final ReaderSourcePresentationPort? sourcePresentationPort;

  /// 阅读进度写入端口；未注入时从组合根读取。
  final ReaderProgressPort? progressPort;

  /// 目录强制刷新端口；未注入时从组合根读取。
  final ReaderChapterRefreshPort? chapterRefreshPort;

  /// 模拟追读书籍读写端口；未注入时从组合根读取。
  final ReaderSimulatedReadingPort? simulatedReadingPort;

  /// 离线缓存下载端口；未注入时从组合根读取。
  final CacheBookDownloadPort? cacheDownloadPort;

  /// 当前目录快照端口；未注入时从组合根读取。
  final ReaderChapterListPort? chapterListPort;

  /// 书源访问和自动换源端口；未注入时从组合根读取。
  final ReaderSourceAccessPort? sourceAccessPort;

  /// 章节缓存状态端口；未注入时从组合根读取。
  final ReaderChapterCacheStatusPort? chapterCacheStatusPort;

  const ReaderPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.allChapters,
    this.initialPageIndex,
    this.initialChapterPos,
    this.prefs,
    this.configPrefs,
    this.contentPort,
    this.imageHeadersPort,
    this.sourcePresentationPort,
    this.progressPort,
    this.chapterRefreshPort,
    this.simulatedReadingPort,
    this.cacheDownloadPort,
    this.chapterListPort,
    this.sourceAccessPort,
    this.chapterCacheStatusPort,
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
  int? _pendingChapterPos; // 章内字符偏移（优先于页索引）
  List<String> _pages = [];
  List<ReaderPageSlice> _pageSlices = [];
  late ReaderSettings _settings;
  late ScrollController _scrollController;
  final GlobalKey<ReaderTurnViewState> _turnKey =
      GlobalKey<ReaderTurnViewState>();
  BookProvider? _bookProvider; // 缓存引用，避免 dispose 时 context.read 崩溃
  late final ReadingRecordPort _readingRecordPort;
  late final TtsPort _ttsPort;
  late final ReaderFontPort _readerFontPort;
  late final ReaderSessionPrefsPort _readerSessionPrefs;
  late final ReaderSelectionPort _readerSelectionPort;
  late final ReaderContentRefetchPort _contentRefetchPort;
  late final ReaderBookmarkReadinessPort _bookmarkReadinessPort;
  late final ReaderProgressSyncPort _progressSyncPort;
  late final ReaderProgressPort _progressPort;
  late final ReaderChapterRefreshPort _chapterRefreshPort;
  late final ReaderSimulatedReadingPort _simulatedReadingPort;
  late final CacheBookDownloadPort _cacheDownloadPort;
  late final ReaderChapterListPort _chapterListPort;
  late final ReaderSourceAccessPort _sourceAccessPort;
  late final ChapterContentCachePort _contentCache;
  late final ReaderChapterCacheStatusPort _chapterCacheStatusPort;
  late final ReaderChapterContentPort _contentPort;
  late final ReaderImageHeadersPort _imageHeadersPort;
  late final ReaderSourcePresentationPort _sourcePresentationPort;
  late final BookReaderPrefsPort _bookReaderPrefs;
  late final ReadBookConfigPrefsPort _configPrefs;
  final _readingSession = ReadingSessionTracker();
  late final DetailedReadingSessionTracker _detailedReadingSession;
  int _lastCountedChapterIndex = -1;
  int _contentRequestGeneration = 0;
  ReaderImageCachePort? _readerImageCache;
  Map<String, ReaderImageSize> _readerImageNaturalSizes = const {};
  Map<String, String> _readerImageHeaders = const {};
  int _imageSizeRequestGeneration = 0;

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

  /// 选区连续朗读：由 TTS 完成事件驱动章节切换，不改正文分页输入。
  bool _continuousReadActive = false;
  int _continuousReadGeneration = 0;
  int _continuousReadChapterIndex = -1;
  int _continuousReadStartPos = 0;
  bool _selectionSpeakContinuously = false;

  /// UI-2: 底栏电量真值
  final Battery _battery = Battery();
  int? _batteryLevel;
  Timer? _batteryTimer;

  /// UI-2: 屏幕超时（legado screenOffTimerStart）
  Timer? _screenOffTimer;

  /// UI-2: 全文搜索结果导航（对齐 searchMenu 上/下个结果）
  List<SearchContentResult> _searchResults = [];
  int _searchResultIndex = -1;
  bool _searchMenuVisible = false;
  int? _pendingSearchOccurrence; // 章内第 N 次命中

  /// UI-2: 模拟追读
  SimulatedReadingConfig _simRead = SimulatedReadingConfig(
    startDate: DateTime.now(),
  );

  /// 首次进入阅读页：点击区域九宫格提示
  bool _showClickRegionTip = false;

  /// 阅读会话：替换净化开关（持久化于 [ReaderSessionPrefs]）
  bool _enableReplace = true;

  /// 本书翻页动画：null=未加载；-1=跟随全局；0..4=本书覆盖
  int? _bookPageAnim;

  /// 本书重新分段
  bool _reSegment = false;

  /// 有效翻页动画（本书优先，否则全局）
  PageAnimMode get _pageAnim {
    final o = _bookPageAnim;
    if (o == null || o < 0) return _settings.pageAnim;
    if (o >= 0 && o < PageAnimMode.values.length) {
      return PageAnimMode.values[o];
    }
    return _settings.pageAnim;
  }

  bool get _isHorizontalPaged => _pageAnim.isHorizontalPaged;

  int get _maxReadableIndex {
    if (!_simRead.enabled) return widget.allChapters.length - 1;
    return _simRead.maxReadableIndex(widget.allChapters.length);
  }

  List<Chapter> get _readableChapters {
    final maxIdx = _maxReadableIndex;
    if (maxIdx < 0) return const [];
    if (!_simRead.enabled) return widget.allChapters;
    return widget.allChapters.take(maxIdx + 1).toList();
  }

  @override
  void initState() {
    super.initState();
    _readingRecordPort = context.read<ReadingRecordPort>();
    _ttsPort = context.read<TtsPort>();
    _readerFontPort = context.read<ReaderFontPort>();
    _readerSessionPrefs = context.read<ReaderSessionPrefsPort>();
    _readerSelectionPort = context.read<ReaderSelectionPort>();
    _contentRefetchPort = context.read<ReaderContentRefetchPort>();
    _bookmarkReadinessPort = context.read<ReaderBookmarkReadinessPort>();
    _progressSyncPort = context.read<ReaderProgressSyncPort>();
    _progressPort = widget.progressPort ?? context.read<ReaderProgressPort>();
    _chapterRefreshPort =
        widget.chapterRefreshPort ??
        Provider.of<ReaderChapterRefreshPort?>(context, listen: false) ??
        const EmptyReaderChapterRefreshPort();
    _simulatedReadingPort =
        widget.simulatedReadingPort ??
        Provider.of<ReaderSimulatedReadingPort?>(context, listen: false) ??
        const EmptyReaderSimulatedReadingPort();
    _cacheDownloadPort =
        widget.cacheDownloadPort ??
        Provider.of<CacheBookDownloadPort?>(context, listen: false) ??
        const EmptyCacheBookDownloadPort();
    _chapterListPort =
        widget.chapterListPort ??
        Provider.of<ReaderChapterListPort?>(context, listen: false) ??
        const EmptyReaderChapterListPort();
    _sourceAccessPort =
        widget.sourceAccessPort ??
        Provider.of<ReaderSourceAccessPort?>(context, listen: false) ??
        const EmptyReaderSourceAccessPort();
    _contentCache = context.read<ChapterContentCachePort>();
    _chapterCacheStatusPort =
        widget.chapterCacheStatusPort ??
        context.read<ReaderChapterCacheStatusPort>();
    _contentPort =
        widget.contentPort ?? context.read<ReaderChapterContentPort>();
    _imageHeadersPort =
        widget.imageHeadersPort ?? context.read<ReaderImageHeadersPort>();
    _sourcePresentationPort =
        widget.sourcePresentationPort ??
        Provider.of<ReaderSourcePresentationPort?>(context, listen: false) ??
        const EmptyReaderSourcePresentationPort();
    _bookReaderPrefs = widget.prefs ?? context.read<BookReaderPrefsPort>();
    _configPrefs =
        widget.configPrefs ?? context.read<ReadBookConfigPrefsPort>();
    _readingSession.start();
    _detailedReadingSession = DetailedReadingSessionTracker(
      bookName: widget.book.name,
      readIteration: widget.book.readIteration,
    )..start();
    _settings = const ReaderSettings();
    _scrollController = ScrollController();
    _currentIndex = widget.allChapters.indexOf(widget.chapter);
    if (_currentIndex < 0) _currentIndex = 0;
    if (widget.initialChapterPos != null && widget.initialChapterPos! >= 0) {
      _pendingChapterPos = widget.initialChapterPos;
    } else if (widget.initialPageIndex != null &&
        widget.initialPageIndex! >= 0) {
      _pendingTargetPage = widget.initialPageIndex;
    } else if (widget.book.currentPageIndex > 0) {
      _pendingTargetPage = widget.book.currentPageIndex;
    }
    _selectionSpeakContinuously =
        _ttsPort.selectionSpeakMode == TtsSelectionSpeakModePort.continuous;
    _ttsPort.addListener(_onTtsServiceChanged);
    _ttsPort.addPlaybackCompletedListener(_onTtsPlaybackCompleted);
    unawaited(_loadSelectionSpeakMode());
    _loadContent();
    unawaited(_loadReaderImageCache());
    _scheduleAutoHide();
    _refreshBattery();
    _batteryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshBattery(),
    );
    _applyScreenTimeout();
    _applySystemUi();
    unawaited(_loadSimulatedReading());
    unawaited(_loadReadStylePrefs());
    unawaited(_loadClickActionPrefs());
    unawaited(_loadReaderSessionPrefs());
    unawaited(_loadBookReaderPrefs());
  }

  Future<void> _loadReaderImageCache() async {
    final cache = context.read<ReaderImageCachePort>();
    if (!mounted) return;
    setState(() => _readerImageCache = cache);
    unawaited(_loadReaderImageSizes());
  }

  Future<void> _loadReaderImageSizes() async {
    final cache = _readerImageCache;
    if (cache == null) return;
    final requestGeneration = ++_imageSizeRequestGeneration;
    final contentGeneration = _contentRequestGeneration;
    final sources = _displayDocument.images
        .map((image) => image.source)
        .toSet();
    if (sources.isEmpty) return;

    final headers = await _imageHeadersPort.imageHeadersForBook(widget.book);
    if (!mounted ||
        requestGeneration != _imageSizeRequestGeneration ||
        contentGeneration != _contentRequestGeneration) {
      return;
    }

    final results = await Future.wait(
      sources.map(
        (source) async =>
            MapEntry(source, await cache.getSize(source, headers: headers)),
      ),
    );
    if (!mounted ||
        requestGeneration != _imageSizeRequestGeneration ||
        contentGeneration != _contentRequestGeneration) {
      return;
    }
    final naturalSizes = <String, ReaderImageSize>{};
    for (final result in results) {
      final size = result.value;
      if (size != null) naturalSizes[result.key] = size;
    }
    setState(() {
      _readerImageHeaders = headers;
      _readerImageNaturalSizes = naturalSizes;
    });
    if (_isHorizontalPaged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isHorizontalPaged) _splitIntoPages();
      });
    }
  }

  String get _readerImageStyle {
    final source = _sourceAccessPort.sourceForBook(widget.book);
    final style = source?.ruleContentImageStyle.trim();
    return style == null || style.isEmpty ? 'DEFAULT' : style.toUpperCase();
  }

  Map<String, Size> _displayImageSizes(double maxWidth, {double? maxHeight}) {
    if (maxWidth <= 0) return const {};
    final sizes = <String, Size>{};
    for (final entry in _readerImageNaturalSizes.entries) {
      final size = ReaderImageLayout.displaySize(
        natural: Size(
          entry.value.width.toDouble(),
          entry.value.height.toDouble(),
        ),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        style: _readerImageStyle,
      );
      if (size != null) sizes[entry.key] = size;
    }
    for (final image in _displayDocument.images) {
      final natural = _readerImageNaturalSizes[image.source];
      if (natural == null) continue;
      final size = ReaderImageLayout.displaySize(
        natural: Size(natural.width.toDouble(), natural.height.toDouble()),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        style: image.style ?? _readerImageStyle,
        widthOverride: ReaderImageLayout.parseWidth(image.width, maxWidth),
      );
      if (size != null) sizes[image.key] = size;
    }
    return sizes;
  }

  double _readerImageMaxHeight() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return double.infinity;
    // Match the original PageView's stable window geometry. `padding` can
    // change when transient overlays are visible; the original layout keeps
    // status/navigation insets as part of its measured view bounds.
    final media = MediaQuery.of(context);
    final edgePadT = _settings.expandIntoCutout ? 0.0 : media.viewPadding.top;
    final edgePadB = _settings.expandIntoCutout
        ? 0.0
        : (media.viewPadding.bottom > media.systemGestureInsets.bottom
              ? media.viewPadding.bottom
              : media.systemGestureInsets.bottom);
    final bottomSystemReserve = _readerBottomSystemReserve(media);
    const pageFooterHeight = 32.0;
    final chapterTitleHeight = _settings.fontSize + 36.0;
    return renderBox.size.height -
        edgePadT -
        edgePadB -
        bottomSystemReserve -
        chapterTitleHeight -
        pageFooterHeight -
        _settings.paddingVertical * 2;
  }

  double _readerBottomSystemReserve(MediaQueryData media) {
    if (_settings.expandIntoCutout ||
        defaultTargetPlatform != TargetPlatform.android) {
      return 0.0;
    }
    final bottomInset =
        media.viewPadding.bottom > media.systemGestureInsets.bottom
        ? media.viewPadding.bottom
        : media.systemGestureInsets.bottom;
    return bottomInset == 0.0 ? media.viewPadding.top : 0.0;
  }

  List<ReaderPaginatorPlaceholder> _imagePlaceholders(
    ReaderMarkupDocument document,
    Map<String, Size> displaySizes,
  ) {
    return [
      for (final image in document.images)
        if (displaySizes[image.key] ?? displaySizes[image.source]
            case final size?)
          ReaderPaginatorPlaceholder(
            start: image.start,
            end: image.end,
            width: size.width,
            height: size.height,
          ),
    ];
  }

  double _readerImageMaxWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return double.infinity;
    final pad = MediaQuery.of(context).padding;
    final edgePadL = _settings.expandIntoCutout ? 0.0 : pad.left;
    final edgePadR = _settings.expandIntoCutout ? 0.0 : pad.right;
    return renderBox.size.width -
        _settings.paddingHorizontal * 2 -
        edgePadL -
        edgePadR;
  }

  Future<void> _loadBookReaderPrefs() async {
    final anim = await _bookReaderPrefs.getPageAnim(widget.book.id);
    final reSeg = await _bookReaderPrefs.getReSegment(widget.book.id);
    if (!mounted) return;
    setState(() {
      _bookPageAnim = anim ?? -1;
      _reSegment = reSeg;
    });
    ReadBook.instance.reSegment = reSeg;
  }

  Future<void> _loadReaderSessionPrefs() async {
    final enableReplace = await _readerSessionPrefs.loadEnableReplace();
    if (!mounted) return;
    setState(() => _enableReplace = enableReplace);
    ReadBook.instance.enableReplace = enableReplace;
  }

  Future<void> _loadClickActionPrefs() async {
    final prefs = context.read<ClickActionPrefsPort>();
    final layout = await prefs.load();
    final tipShown = await prefs.isTipShown();
    if (!mounted) return;
    setState(() {
      _settings = _settings.copyWith(
        clickTL: layout.tl,
        clickTC: layout.tc,
        clickTR: layout.tr,
        clickML: layout.ml,
        clickMC: layout.mc,
        clickMR: layout.mr,
        clickBL: layout.bl,
        clickBC: layout.bc,
        clickBR: layout.br,
      );
      _showClickRegionTip = !tipShown;
    });
  }

  Future<void> _dismissClickRegionTip() async {
    if (!_showClickRegionTip) return;
    setState(() => _showClickRegionTip = false);
    await context.read<ClickActionPrefsPort>().markTipShown();
  }

  ClickZoneLayout get _clickLayout => ClickZoneLayout(
    tl: _settings.clickTL,
    tc: _settings.clickTC,
    tr: _settings.clickTR,
    ml: _settings.clickML,
    mc: _settings.clickMC,
    mr: _settings.clickMR,
    bl: _settings.clickBL,
    bc: _settings.clickBC,
    br: _settings.clickBR,
  );

  Future<void> _loadSimulatedReading() async {
    final prefs = context.read<SimulatedReadingPrefsPort>();
    final book =
        _simulatedReadingPort.findBookById(widget.book.id) ?? widget.book;
    final loaded = await prefs.loadForBook(book);
    var cfg = loaded.config;
    if (loaded.needsBookMigrate) {
      final persisted = await _simulatedReadingPort.updateSimulatedReading(
        book,
        enabled: cfg.enabled,
        startDate: SimulatedReadingConfig.formatDate(cfg.startDate),
        startChapter: cfg.startChapter,
        dailyChapters: cfg.dailyChapters,
      );
      cfg = SimulatedReadingConfig.fromBook(persisted);
      await prefs.save(widget.book.id, cfg);
    }
    if (!mounted) return;
    setState(() => _simRead = cfg);
    if (cfg.enabled &&
        _currentIndex > _maxReadableIndex &&
        _maxReadableIndex >= 0) {
      _goToChapter(_maxReadableIndex);
    }
  }

  Future<void> _loadReadStylePrefs() async {
    // 对齐 Jingshiro ReadBookConfig.initConfigs + initShareConfig
    final stylePrefs = context.read<ReadStylePrefsPort>();
    final saved = await _configPrefs.load();
    final share = await stylePrefs.loadShareLayout();
    final overrides = await stylePrefs.loadOverrides();
    final themeName = await stylePrefs.loadThemeName();
    if (!mounted) return;
    var next = saved.copyWith(
      shareLayout: share,
      themeOverrides: overrides,
      themeName: themeName,
    );
    if (!share) {
      final typo = await stylePrefs.loadTypography(themeName);
      if (typo != null) next = typo.applyToReaderSettings(next);
    }
    if (!mounted) return;
    setState(() => _settings = next);
    _applyScreenOrientation(next.screenOrientation);
    _applyScreenTimeout();
    _applySystemUi();
    unawaited(_ensureReaderFontLoaded());
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

  /// 对齐 legado keepLight / screenOffTimerStart：
  /// 0 跟随系统；正秒数内保持亮屏后释放；-1 常亮；自动阅读时强制常亮。
  void _applyScreenTimeout({bool forceAlways = false}) {
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    final always =
        forceAlways ||
        _autoReadRunning ||
        _settings.screenTimeout == ScreenTimeoutMode.always;
    if (always) {
      unawaited(_applyKeepScreenOn(true));
      return;
    }
    final sec = _settings.screenTimeout.seconds;
    if (sec <= 0) {
      unawaited(_applyKeepScreenOn(false));
      return;
    }
    unawaited(_applyKeepScreenOn(true));
    _screenOffTimer = Timer(Duration(seconds: sec), () {
      if (!mounted) return;
      unawaited(_applyKeepScreenOn(false));
    });
  }

  void _bumpScreenTimeout() {
    if (_settings.screenTimeout.seconds > 0 ||
        _settings.screenTimeout == ScreenTimeoutMode.always ||
        _autoReadRunning) {
      _applyScreenTimeout();
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
        statusBarIconBrightness: darkTheme ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: darkTheme
            ? Brightness.light
            : Brightness.dark,
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
    final paragraphs = text.split('\n');
    final out = StringBuffer();
    for (var i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      if (p.trim() == '[newpage]') {
        out.write('[newpage]');
        if (i < paragraphs.length - 1) out.write('\n');
        continue;
      }
      if (p.trim().isEmpty) {
        out.writeln();
        continue;
      }
      final body = p.replaceFirst(RegExp(r'^[\s　]+'), '');
      out.write(indent);
      out.write(body);
      if (i < paragraphs.length - 1) {
        out.write('\n');
      }
    }
    return out.toString();
  }

  String get _displayMarkup => _prepareDisplayText(_content);

  String get _displayContent => ReaderMarkup.toPlainText(_displayMarkup);

  ReaderMarkupDocument get _displayDocument =>
      ReaderMarkup.parse(_displayMarkup);

  ReaderMarkupDocument get _displayDocumentWithoutHardPageBreaks =>
      ReaderMarkup.parse(_displayMarkup, removeHardPageBreaks: true);

  String get _displayContentWithoutHardPageBreaks =>
      _displayDocumentWithoutHardPageBreaks.plainText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookProvider = context.read<BookProvider>();
  }

  @override
  void dispose() {
    // 让 dispose 前已经发出的网络结果无法再提交到阅读器状态。
    _contentRequestGeneration++;
    _imageSizeRequestGeneration++;
    _autoHideTimer?.cancel();
    _autoReadTimer?.cancel();
    _batteryTimer?.cancel();
    _screenOffTimer?.cancel();
    _ttsPort.removeListener(_onTtsServiceChanged);
    _ttsPort.removePlaybackCompletedListener(_onTtsPlaybackCompleted);
    if (_continuousReadActive) {
      _continuousReadActive = false;
      _continuousReadGeneration++;
      unawaited(_ttsPort.stop());
    }
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    unawaited(_applyKeepScreenOn(false));
    _saveProgress();
    _flushReadingSession();
    final detailed = _detailedReadingSession.stop();
    if (detailed != null) {
      _readingRecordPort.recordDetailedReadSession(
        bookName: detailed.bookName,
        startTime: detailed.startTime,
        endTime: detailed.endTime,
        readIteration: detailed.readIteration,
      );
    }
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setAutoReadRunning(bool running) {
    _autoReadTimer?.cancel();
    _autoReadTimer = null;
    setState(() => _autoReadRunning = running);
    // 自动阅读时 legado 强制常亮；停止后恢复 keepLight 分档
    _applyScreenTimeout();
    if (!running) return;
    final interval = Duration(
      milliseconds: (_settings.autoReadIntervalSec * 1000).round(),
    );
    _autoReadTimer = Timer.periodic(interval, (_) {
      if (!mounted || !_autoReadRunning) return;
      final lastIdx = _maxReadableIndex;
      final atLastPage =
          _isHorizontalPaged &&
          _pages.isNotEmpty &&
          _pageIndex >= _pages.length - 1 &&
          _currentIndex >= lastIdx;
      final atLastChapterScroll =
          !_isHorizontalPaged && _currentIndex >= lastIdx;
      if (atLastPage || atLastChapterScroll) {
        _setAutoReadRunning(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _simRead.enabled ? '已到模拟追读上限，自动阅读已停止' : '已到全书末尾，自动阅读已停止',
            ),
          ),
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
    // 菜单已显示时点翻页区：只收起菜单（对齐 legado vwMenuBg），避免「翻页+出菜单」双动作
    if (_chromeVisible && action != ClickZoneAction.menu) {
      _hideChrome();
      return;
    }
    switch (action) {
      case ClickZoneAction.none:
        break;
      case ClickZoneAction.menu:
        _toggleChrome();
      case ClickZoneAction.nextPage:
        _nextPage();
      case ClickZoneAction.prevPage:
        _prevPage();
      case ClickZoneAction.nextChapter:
        if (_currentIndex < widget.allChapters.length - 1) {
          _goToChapter(_currentIndex + 1);
        }
      case ClickZoneAction.prevChapter:
        if (_currentIndex > 0) _goToChapter(_currentIndex - 1);
      case ClickZoneAction.aloudPrevParagraph:
        unawaited(_ttsPort.previousSentence());
      case ClickZoneAction.aloudNextParagraph:
        unawaited(_ttsPort.nextSentence());
      case ClickZoneAction.addBookmark:
        unawaited(_addBookmark());
      case ClickZoneAction.editContent:
        unawaited(_openContentEdit());
      case ClickZoneAction.replaceToggle:
        unawaited(_toggleReplacePurify());
      case ClickZoneAction.chapterList:
        unawaited(_showTocSheet());
      case ClickZoneAction.searchContent:
        unawaited(_openContentSearch());
      case ClickZoneAction.syncProgress:
        unawaited(_syncReadingProgress());
      case ClickZoneAction.aloudPauseResume:
        unawaited(_toggleAloudPauseResume());
    }
  }

  Future<void> _toggleAloudPauseResume() async {
    final tts = _ttsPort;
    final text = _pages.isNotEmpty
        ? _pages[_pageIndex.clamp(0, _pages.length - 1)]
        : _content;
    await tts.togglePlay(text);
  }

  // TODO(refactor): 将 _buildClickZones/cell/row 提取到独立 widget 文件。
  /// 九宫格点击热区（对齐 ReadView.setRect9x：宽高各约 1/3）
  Widget _buildClickZones() {
    Widget cell(ClickZoneAction action) {
      return Expanded(
        child: GestureDetector(
          onTap: () => _runClickAction(action),
          behavior: HitTestBehavior.translucent,
        ),
      );
    }

    Widget row(ClickZoneAction l, ClickZoneAction c, ClickZoneAction r) {
      return Expanded(child: Row(children: [cell(l), cell(c), cell(r)]));
    }

    return Column(
      children: [
        row(_settings.clickTL, _settings.clickTC, _settings.clickTR),
        row(_settings.clickML, _settings.clickMC, _settings.clickMR),
        row(_settings.clickBL, _settings.clickBC, _settings.clickBR),
      ],
    );
  }

  /// Map a local offset to the 9-grid click action (same thirds as overlay zones).
  ClickZoneAction _clickActionAt(Offset local, Size size) {
    final col = local.dx < size.width / 3
        ? 0
        : (local.dx < size.width * 2 / 3 ? 1 : 2);
    final row = local.dy < size.height / 3
        ? 0
        : (local.dy < size.height * 2 / 3 ? 1 : 2);
    return switch ((row, col)) {
      (0, 0) => _settings.clickTL,
      (0, 1) => _settings.clickTC,
      (0, 2) => _settings.clickTR,
      (1, 0) => _settings.clickML,
      (1, 1) => _settings.clickMC,
      (1, 2) => _settings.clickMR,
      (2, 0) => _settings.clickBL,
      (2, 1) => _settings.clickBC,
      _ => _settings.clickBR,
    };
  }

  /// Parent of [ScrollView]: taps go to click actions; vertical drag stays scrollable.
  /// Do NOT use a Stack overlay of GestureDetectors — that steals hit tests from ScrollView.
  Widget _wrapScrollWithClickZones(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return ScrollConfiguration(
          // Windows/desktop: enable mouse/trackpad drag (Material default is touch-only).
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              _runClickAction(_clickActionAt(details.localPosition, size));
            },
            child: child,
          ),
        );
      },
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
      onOpenAudioPlayer: _openAudioPlayPage,
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  /// UI-22：有声播放器（对齐 activity_audio_play）
  Future<void> _openAudioPlayPage() async {
    _autoHideTimer?.cancel();
    final chapters = _readableChapters.isNotEmpty
        ? _readableChapters
        : widget.allChapters;
    if (chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂无章节，无法打开有声播放器')));
      }
      return;
    }
    final idx = _currentIndex.clamp(0, chapters.length - 1);
    await AudioPlayPage.open(
      context,
      book: widget.book,
      chapters: chapters,
      initialChapterIndex: idx,
      initialContent: _content,
      onChapterChanged: (i) {
        if (mounted && i != _currentIndex) _goToChapter(i);
      },
    );
    if (mounted) _scheduleAutoHide();
  }

  /// UI-23：漫画阅读器（对齐 activity_manga）
  Future<void> _openMangaReader() async {
    _autoHideTimer?.cancel();
    final chapters = _readableChapters.isNotEmpty
        ? _readableChapters
        : widget.allChapters;
    if (chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂无章节，无法打开漫画阅读器')));
      }
      return;
    }
    final idx = _currentIndex.clamp(0, chapters.length - 1);
    await MangaReaderPage.open(
      context,
      book: widget.book,
      chapters: chapters,
      initialChapterIndex: idx,
      initialContent: _content,
    );
    if (mounted) _scheduleAutoHide();
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

  void _hideChrome() {
    if (!_chromeVisible) return;
    setState(() => _chromeVisible = false);
    _applySystemUi();
    _autoHideTimer?.cancel();
  }

  void _toggleChrome() {
    if (_chromeVisible) {
      _hideChrome();
      return;
    }
    setState(() => _chromeVisible = true);
    _applySystemUi();
    _scheduleAutoHide();
  }

  void _keepChromeAlive() {
    if (!_chromeVisible) {
      setState(() => _chromeVisible = true);
      _applySystemUi();
    }
    _scheduleAutoHide();
  }

  /// 对齐 legado ReadMenu.vwMenuBg：菜单展开时点正文区只收菜单，不穿透到九宫格翻页。
  /// 必须用 translucent：opaque 会抢走 ScrollView 的命中，滚动模式无法拖拽。
  Widget _chromeDismissScrim() {
    if (!_chromeVisible) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideChrome,
      ),
    );
  }

  void _countChapterChars(String content) {
    if (content.startsWith('⚠️') || content.contains('未找到匹配的书源')) {
      return;
    }
    if (_currentIndex == _lastCountedChapterIndex) return;
    _readingSession.addChars(content.length);
    _lastCountedChapterIndex = _currentIndex;
  }

  void _flushReadingSession() {
    final delta = _readingSession.pending();
    if (delta == null) return;
    final committed = _readingRecordPort.recordReading(
      bookId: widget.book.id,
      bookName: widget.book.name,
      chars: delta.chars,
      durationSeconds: delta.durationSeconds,
    );
    if (committed) _readingSession.commit(delta);
  }

  Future<void> _openNoteEditor(String selectedText) async {
    await _openNoteEditorAt(selectedText, -1);
  }

  Future<void> _openNoteEditorAt(String selectedText, int chapterPos) async {
    if (selectedText.trim().isEmpty) return;
    final chapter = widget.allChapters[_currentIndex];
    await showNoteEditorSheet(
      context,
      book: widget.book,
      chapterTitle: chapter.title,
      selectedText: selectedText.trim(),
      position: _currentIndex,
      chapterPos: chapterPos,
    );
  }

  Future<void> _addSelectedBookmark(String selectedText, int chapterPos) async {
    final text = selectedText.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法为空文本添加书签')));
      }
      return;
    }
    if (!_bookmarkReadinessPort.isReady) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('引擎未就绪，无法添加书签')));
      }
      return;
    }
    final chapter = widget.allChapters[_currentIndex];
    final saved = await showBookmarkEditorSheet(
      context,
      book: widget.book,
      chapterTitle: chapter.title,
      chapterIndex: _currentIndex,
      chapterPos: chapterPos,
      bookText: text,
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已添加书签')));
  }

  TextStyle _readerTextStyle(Color color) {
    return _readerFontPort.contentTextStyle(
      settings: _settings,
      color: color,
      renderedLineHeight: _renderedLineHeight,
    );
  }

  Future<void> _readSelectedText(String selectedText) async {
    final text = selectedText.trim();
    if (text.isEmpty) return;
    final started = await _ttsPort.speakSelection(text);
    if (!mounted || started || _ttsPort.state != TtsPlaybackStatePort.playing) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('系统语音引擎不可用，请检查 TTS 权限或语音包')));
  }

  Future<void> _openSelectedDictionary(String selectedText) async {
    await showDictLookupSheet(context, selectedText);
  }

  Future<void> _openSelectedContentSearch(String selectedText) async {
    final query = selectedText.trim();
    if (query.isEmpty) return;
    await _openContentSearch(initialQuery: query);
  }

  Future<void> _openSelectedBrowser(String selectedText) async {
    final uri = _readerSelectionPort.browserUri(selectedText);
    if (uri == null) return;
    if (!_readerSelectionPort.isAbsoluteWebUrl(selectedText) &&
        await _readerSelectionPort.tryNativeWebSearch(selectedText)) {
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开浏览器')));
    }
  }

  Future<void> _shareSelectedText(String selectedText) async {
    final text = _readerSelectionPort.shareText(selectedText);
    if (text == null) return;
    try {
      await Share.share(text, subject: _readerSelectionPort.shareSubject);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法分享选中文本')));
    }
  }

  Future<void> _loadSelectionSpeakMode() async {
    await _ttsPort.loadSelectionSpeakMode();
    if (!mounted) return;
    setState(() {
      _selectionSpeakContinuously =
          _ttsPort.selectionSpeakMode == TtsSelectionSpeakModePort.continuous;
    });
  }

  void _setSelectionSpeakMode(bool continuous) {
    _ttsPort.setSelectionSpeakMode(
      continuous
          ? TtsSelectionSpeakModePort.continuous
          : TtsSelectionSpeakModePort.selection,
    );
    if (mounted) {
      setState(() => _selectionSpeakContinuously = continuous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(continuous ? '切换为从选择位置开始一直朗读' : '切换为朗读选择内容'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  void _onTtsServiceChanged() {
    if (!_continuousReadActive) return;
    _syncContinuousReadPosition();
  }

  void _onTtsPlaybackCompleted() {
    if (!_continuousReadActive) return;
    unawaited(_continueSelectedTextReading(_continuousReadGeneration));
  }

  Future<void> _readSelectedTextFromPosition(
    String selectedText,
    int chapterPos,
  ) async {
    // The selection text is retained by the callback contract; the continuous
    // mode intentionally reads the remaining chapter, starting at chapterPos.
    if (selectedText.isEmpty) return;
    final source = _isHorizontalPaged
        ? _displayContent
        : _displayContentWithoutHardPageBreaks;
    if (source.trim().isEmpty) return;

    _cancelContinuousReading();
    await _ttsPort.stop();
    final generation = ++_continuousReadGeneration;
    _continuousReadActive = true;
    _continuousReadChapterIndex = _currentIndex;
    _continuousReadStartPos = chapterPos.clamp(0, source.length);
    _syncContinuousReadPosition();

    final started = await _ttsPort.speakFromOffset(
      source,
      _continuousReadStartPos,
    );
    if (!mounted || generation != _continuousReadGeneration) return;
    if (!started && _ttsPort.sentenceCount == 0) {
      _finishContinuousReading();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前章节没有可朗读的正文')));
    } else if (!started && _ttsPort.capability == TtsCapabilityPort.stub) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系统语音引擎不可用，请检查 TTS 权限或语音包')));
    }
  }

  void _cancelContinuousReading() {
    if (!_continuousReadActive) return;
    _continuousReadActive = false;
    _continuousReadGeneration++;
    unawaited(_ttsPort.stop());
  }

  void _finishContinuousReading() {
    _continuousReadActive = false;
    _continuousReadGeneration++;
    _continuousReadChapterIndex = -1;
    _continuousReadStartPos = 0;
  }

  Future<void> _continueSelectedTextReading(int generation) async {
    if (!mounted ||
        !_continuousReadActive ||
        generation != _continuousReadGeneration) {
      return;
    }
    final nextIndex = _continuousReadChapterIndex + 1;
    if (nextIndex > _maxReadableIndex ||
        nextIndex >= widget.allChapters.length) {
      _finishContinuousReading();
      return;
    }

    await _goToChapter(
      nextIndex,
      chapterPos: 0,
      preserveContinuousReading: true,
    );
    if (!mounted ||
        !_continuousReadActive ||
        generation != _continuousReadGeneration ||
        _currentIndex != nextIndex) {
      return;
    }
    final source = _isHorizontalPaged
        ? _displayContent
        : _displayContentWithoutHardPageBreaks;
    if (source.trim().isEmpty) {
      _finishContinuousReading();
      return;
    }
    _continuousReadChapterIndex = nextIndex;
    _continuousReadStartPos = 0;
    _syncContinuousReadPosition();
    await _ttsPort.speakFromOffset(source, 0);
  }

  void _syncContinuousReadPosition() {
    if (!mounted ||
        !_continuousReadActive ||
        _currentIndex != _continuousReadChapterIndex) {
      return;
    }
    final textOffset = (_continuousReadStartPos + _ttsPort.currentTextOffset)
        .clamp(0, 0x7fffffff);
    if (_isHorizontalPaged && _pageSlices.isNotEmpty) {
      var target = _pageSlices.length - 1;
      for (var i = 0; i < _pageSlices.length; i++) {
        final slice = _pageSlices[i];
        if (textOffset < slice.end || i == _pageSlices.length - 1) {
          target = i;
          break;
        }
      }
      if (target != _pageIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _continuousReadActive && target != _pageIndex) {
            setState(() => _pageIndex = target);
          }
        });
      }
      return;
    }
    if (!_isHorizontalPaged &&
        _scrollController.hasClients &&
        _displayContentWithoutHardPageBreaks.isNotEmpty) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final ratio = (textOffset / _displayContentWithoutHardPageBreaks.length)
          .clamp(0.0, 1.0);
      final target = maxScroll * ratio;
      if ((_scrollController.offset - target).abs() > 12) {
        _scrollController.jumpTo(target.clamp(0.0, maxScroll));
      }
    }
  }

  double? get _renderedLineHeight =>
      _readerFontPort.renderedLineHeight(settings: _settings);

  TextAlign get _readerTextAlign =>
      _settings.textFullJustify ? TextAlign.justify : TextAlign.start;

  Future<void> _ensureReaderFontLoaded() async {
    final family = _settings.fontFamily;
    if (!_readerFontPort.isFontFilePath(family)) return;
    final loadedFamily = await _readerFontPort.ensureLoaded(family);
    if (!mounted || _settings.fontFamily != family || loadedFamily == null) {
      return;
    }
    setState(() {});
    if (_isHorizontalPaged && !_isLoading && _content.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isHorizontalPaged && !_isLoading) {
          _splitIntoPages();
        }
      });
    }
  }

  bool get _isEmptyBody => ReadBook.isEmptyContentPlaceholder(_content);

  /// 书源展示：优先书源名，其次书籍来源 URL
  String get _sourceSubtitle {
    final name = _sourceDisplayName;
    if (name.isNotEmpty) return name;
    return _chapterUrlLabel;
  }

  /// 顶栏书源芯片文案（书源名；无名称时用 host）
  String get _sourceDisplayName =>
      _sourcePresentationPort.sourceNameForBook(widget.book);

  /// 顶栏第三行：当前章源地址
  String get _chapterUrlLabel {
    final chUrl = widget.allChapters[_currentIndex].url;
    if (chUrl.isNotEmpty) return chUrl;
    if (widget.book.bookSourceUrl.isNotEmpty) return widget.book.bookSourceUrl;
    return widget.book.sourceUrl;
  }

  /// 阅读菜单强调色（对齐 legado 橙）
  static const Color _chromeAccent = Color(0xFFFF6D00);

  Future<void> _loadContent({bool forceRefresh = false}) async {
    final requestGeneration = ++_contentRequestGeneration;
    _imageSizeRequestGeneration++;
    setState(() => _isLoading = true);
    try {
      final chapter = widget.allChapters[_currentIndex];
      final source = _sourceAccessPort.sourceForBook(widget.book);
      String content;
      if (source != null) {
        final rb = ReadBook.instance;
        if (rb.book?.id != widget.book.id ||
            rb.bookSource?.bookSourceUrl != source.bookSourceUrl ||
            rb.chapters.length != widget.allChapters.length) {
          rb.open(
            currentBook: widget.book,
            source: source,
            chapterList: widget.allChapters,
            startIndex: _currentIndex,
          );
        } else {
          rb.durChapterIndex = _currentIndex;
        }
        if (forceRefresh) {
          await ReadBook.instance.invalidateChapterCache(
            chapter.id,
            bookId: widget.book.id,
          );
        }
        content = await _contentPort.loadChapterContent(
          book: widget.book,
          chapter: chapter,
        );
      } else {
        content = '⚠️ 未找到匹配的书源';
      }
      if (mounted && requestGeneration == _contentRequestGeneration) {
        setState(() {
          _content = content.contains('（加载失败')
              ? '⚠️ 加载失败，请检查网络\n\n$content'
              : content;
          _readerImageNaturalSizes = const {};
          _readerImageHeaders = const {};
          _isLoading = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isHorizontalPaged) {
              _splitIntoPages();
            }
          });
        });
        unawaited(_loadReaderImageSizes());
        final ok =
            !ReadBook.isEmptyContentPlaceholder(content) &&
            !content.contains('（加载失败') &&
            !content.startsWith('⚠️');
        if (ok) {
          _chapterCacheStatusPort.markChapterDownloaded(chapter.id);
        }
        _countChapterChars(content);
        _syncPreload();
        _applyPendingSearchJump();
      }
    } catch (e) {
      if (mounted && requestGeneration == _contentRequestGeneration) {
        setState(() {
          _isLoading = false;
          _content = '⚠️ 无法加载章节内容\n\n请检查网络连接，或尝试其他书源。\n\n错误: $e';
        });
      }
    }
  }

  void _applyPendingSearchJump() {
    final occ = _pendingSearchOccurrence;
    if (occ == null) return;
    _pendingSearchOccurrence = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isHorizontalPaged) {
        if (_pages.isEmpty) {
          _splitIntoPages();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _jumpToOccurrenceInChapter(occ);
        });
      } else {
        _jumpToOccurrenceInChapter(occ);
      }
    });
  }

  int _nthQueryIndex(String text, String query, int n) {
    if (query.isEmpty) return -1;
    var from = 0;
    for (var i = 0; i <= n; i++) {
      final idx = text.indexOf(query, from);
      if (idx < 0) return -1;
      if (i == n) return idx;
      from = idx + query.length;
    }
    return -1;
  }

  void _jumpToOccurrenceInChapter(int occurrence) {
    if (_searchResults.isEmpty || _searchResultIndex < 0) return;
    final q = _searchResults[_searchResultIndex].query;
    final text = _displayContent;
    final charIdx = _nthQueryIndex(text, q, occurrence);
    if (charIdx < 0) return;
    if (_isHorizontalPaged && _pages.isNotEmpty) {
      for (var i = 0; i < _pageSlices.length; i++) {
        final page = _pageSlices[i];
        if (charIdx >= page.start && charIdx < page.end) {
          setState(() => _pageIndex = i);
          break;
        }
      }
    } else if (_scrollController.hasClients && text.isNotEmpty) {
      final max = _scrollController.position.maxScrollExtent;
      final ratio = (charIdx / text.length).clamp(0.0, 1.0);
      _scrollController.jumpTo(max * ratio);
    }
  }

  Future<void> _openContentSearch({
    String? initialQuery,
    List<SearchContentResult>? results,
    int resultIndex = 0,
  }) async {
    _autoHideTimer?.cancel();
    final nav = await SearchContentPage.open(
      context,
      bookId: widget.book.id,
      bookName: widget.book.name,
      chapters: _readableChapters.isNotEmpty
          ? _readableChapters
          : widget.allChapters,
      durChapterIndex: _currentIndex,
      currentChapterContent: _content,
      contentCache: context.read<ChapterContentCachePort>(),
      onlineContentLoader: (chapter) async {
        final content = await _contentPort.loadChapterContent(
          book: widget.book,
          chapter: chapter,
        );
        return content == '未找到匹配的书源' ? null : content;
      },
      initialQuery:
          initialQuery ??
          (results != null && results.isNotEmpty
              ? results[resultIndex.clamp(0, results.length - 1)].query
              : null),
      initialResults: results,
      initialResultIndex: resultIndex,
    );
    if (!mounted) return;
    if (nav != null && nav.results.isNotEmpty) {
      await _applySearchNavigation(nav);
    }
    _scheduleAutoHide();
  }

  Future<void> _applySearchNavigation(SearchContentNavigate nav) async {
    setState(() {
      _searchResults = nav.results;
      _searchResultIndex = nav.index.clamp(0, nav.results.length - 1);
      _searchMenuVisible = true;
      _chromeVisible = false;
    });
    await _gotoSearchResult(_searchResultIndex);
  }

  Future<void> _gotoSearchResult(int index) async {
    if (_searchResults.isEmpty) return;
    final i = index.clamp(0, _searchResults.length - 1);
    final r = _searchResults[i];
    if (r.chapterIndex < 0 || r.chapterIndex >= widget.allChapters.length) {
      return;
    }
    if (_simRead.enabled && r.chapterIndex > _maxReadableIndex) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('模拟追读未解锁该章节')));
      return;
    }
    setState(() => _searchResultIndex = i);
    _pendingSearchOccurrence = r.resultCountWithinChapter;
    if (r.chapterIndex != _currentIndex) {
      _goToChapter(r.chapterIndex);
    } else {
      _applyPendingSearchJump();
    }
  }

  void _searchPrev() {
    if (!_searchMenuVisible || _searchResults.isEmpty) return;
    if (_searchResultIndex <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已是第一个结果')));
      return;
    }
    unawaited(_gotoSearchResult(_searchResultIndex - 1));
  }

  void _searchNext() {
    if (!_searchMenuVisible || _searchResults.isEmpty) return;
    if (_searchResultIndex >= _searchResults.length - 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已是最后一个结果')));
      return;
    }
    unawaited(_gotoSearchResult(_searchResultIndex + 1));
  }

  void _exitSearchMenu() {
    setState(() {
      _searchMenuVisible = false;
      _searchResults = [];
      _searchResultIndex = -1;
      _pendingSearchOccurrence = null;
    });
  }

  Future<void> _openSimulatedReading() async {
    _autoHideTimer?.cancel();
    final next = await SimulatedReadingDialog.show(
      context,
      initial: _simRead,
      totalChapters: widget.allChapters.length,
      durChapterIndex: _currentIndex,
    );
    if (!mounted) return;
    if (next != null) {
      final prefs = context.read<SimulatedReadingPrefsPort>();
      final book =
          _simulatedReadingPort.findBookById(widget.book.id) ?? widget.book;
      await _simulatedReadingPort.updateSimulatedReading(
        book,
        enabled: next.enabled,
        startDate: SimulatedReadingConfig.formatDate(next.startDate),
        startChapter: next.startChapter,
        dailyChapters: next.dailyChapters,
      );
      await prefs.save(widget.book.id, next);
      if (!mounted) return;
      setState(() => _simRead = next);
      if (next.enabled &&
          _currentIndex > _maxReadableIndex &&
          _maxReadableIndex >= 0) {
        _goToChapter(_maxReadableIndex);
      }
      final unlocked = _simRead.simulatedTotalChapterNum(
        widget.allChapters.length,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.enabled ? '模拟追读已开启 · 今日可读 $unlocked 章' : '模拟追读已关闭',
          ),
        ),
      );
    }
    if (mounted) _scheduleAutoHide();
  }

  Widget _buildSearchMenuOverlay(ReaderTheme theme) {
    if (!_searchMenuVisible || _searchResults.isEmpty) {
      return const SizedBox.shrink();
    }
    final idx = _searchResultIndex.clamp(0, _searchResults.length - 1);
    final info = '${idx + 1}/${_searchResults.length}';
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: FloatingActionButton.small(
              heroTag: 'search_prev',
              tooltip: '上个结果',
              backgroundColor: theme.appBar.withValues(alpha: 0.92),
              onPressed: _searchPrev,
              child: Icon(Icons.chevron_left, color: theme.text),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: FloatingActionButton.small(
              heroTag: 'search_next',
              tooltip: '下个结果',
              backgroundColor: theme.appBar.withValues(alpha: 0.92),
              onPressed: _searchNext,
              child: Icon(Icons.chevron_right, color: theme.text),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            elevation: 8,
            color: theme.appBar.withValues(alpha: 0.97),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '结果列表',
                      icon: Icon(Icons.list_alt, color: theme.text),
                      onPressed: () => _openContentSearch(
                        results: _searchResults,
                        resultIndex: idx,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '全文搜索 $info',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.text, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      tooltip: '退出',
                      icon: Icon(Icons.close, color: theme.text),
                      onPressed: _exitSearchMenu,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 将正文按屏幕高度拆分为独立页面（仅 slide 模式）
  void _splitIntoPages() {
    if (_content.isEmpty || !mounted) return;
    if (!_isHorizontalPaged) return;
    // 空章占位不进 PageView，由 _buildBodyText 展示刷新引导
    if (ReadBook.isEmptyContentPlaceholder(_content)) {
      setState(() {
        _pages = [];
        _pageSlices = [];
        _pageIndex = 0;
      });
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // 布局尚未就绪时再试一次（模式切换后常见）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isHorizontalPaged) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) _splitIntoPages();
      });
      return;
    }

    // Use stable system insets. `padding` changes with transient system UI
    // visibility, while the original reader keeps the page window fixed.
    final media = MediaQuery.of(context);
    final pad = media.viewPadding;
    final edgePadL = _settings.expandIntoCutout ? 0.0 : pad.left;
    final edgePadR = _settings.expandIntoCutout ? 0.0 : pad.right;
    final edgePadT = _settings.expandIntoCutout ? 0.0 : pad.top;
    final edgePadB = _settings.expandIntoCutout
        ? 0.0
        : (pad.bottom > media.systemGestureInsets.bottom
              ? pad.bottom
              : media.systemGestureInsets.bottom);
    final bottomSystemReserve = _readerBottomSystemReserve(media);
    final displayDocument = _displayDocument;
    final display = displayDocument.plainText;
    final hPad = _settings.paddingHorizontal * 2;
    final pageWidth = renderBox.size.width - hPad - edgePadL - edgePadR;
    // The original TextChapterLayout receives the content view height. The
    // chapter title is part of the laid-out chapter text, not a fixed chrome
    // reservation. Only the native-style footer is outside that view.
    const pageFooterHeight = 32.0;
    final pageHeight =
        renderBox.size.height -
        edgePadT -
        edgePadB -
        bottomSystemReserve -
        pageFooterHeight -
        _settings.paddingVertical * 2;
    final displayImageSizes = _displayImageSizes(
      pageWidth,
      maxHeight: pageHeight,
    );
    final imagePlaceholders = _imagePlaceholders(
      displayDocument,
      displayImageSizes,
    );

    final slices = <ReaderPageSlice>[];
    if (pageWidth <= 0 || pageHeight <= 0) {
      slices.add(ReaderPageSlice(text: display, start: 0, end: display.length));
    } else {
      slices.addAll(
        ReaderPaginator.paginate(
          text: display,
          style: _readerTextStyle(Colors.black),
          maxWidth: pageWidth,
          maxHeight: pageHeight,
          renderedLineHeight: _renderedLineHeight,
          textAlign: _readerTextAlign,
          paragraphSpacingTenths: _settings.paragraphSpacing * 10,
          placeholders: imagePlaceholders,
          singleImageStyle: _readerImageStyle == 'SINGLE',
        ),
      );
    }

    if (slices.isEmpty) {
      slices.add(ReaderPageSlice(text: display, start: 0, end: display.length));
    }
    final result = slices.map((page) => page.text).toList();

    final targetPage = ReadingPositionMapper.resolvePageIndex(
      pages: [
        for (final page in slices)
          ReadingPageRange(text: page.text, start: page.start, end: page.end),
      ],
      chapterPosition: _pendingChapterPos,
      requestedPageIndex: _pendingTargetPage,
    );
    final clampedPage = targetPage.clamp(0, slices.length - 1);

    setState(() {
      _pages = result;
      _pageSlices = slices;
      _pageIndex = clampedPage;
      _pendingTargetPage = null;
      _pendingChapterPos = null;
    });
    debugPrint(
      '📖 分页完成: ${result.length} 页 (目标=$clampedPage, 页宽=$pageWidth, 页高=$pageHeight)',
    );
  }

  /// 设置面板变更：翻页模式切换时先卸树，再 post-frame dispose 控制器
  void _onSettingsChanged(ReaderSettings newSettings) {
    if (newSettings.screenOrientation != _settings.screenOrientation) {
      _applyScreenOrientation(newSettings.screenOrientation);
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
    final needRepaginate =
        PageAnimMode.fromId(newMode).isHorizontalPaged &&
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
            newSettings.textFullJustify != _settings.textFullJustify ||
            newSettings.textBottomJustify != _settings.textBottomJustify);

    // Jingshiro ReadStyleDialog：改全局翻页时 book.setPageAnim(-1)，dismiss 时 ReadBookConfig.save()
    if (modeChanged) {
      unawaited(_bookReaderPrefs.setPageAnim(widget.book.id, -1));
    }
    unawaited(_configPrefs.save(newSettings));
    final stylePrefs = context.read<ReadStylePrefsPort>();
    unawaited(stylePrefs.saveShareLayout(newSettings.shareLayout));
    unawaited(stylePrefs.saveThemeName(newSettings.themeName));

    if (modeChanged) {
      setState(() {
        _settings = newSettings;
        _bookPageAnim = -1;
        _pages = [];
        _pageIndex = 0;
        _modeGeneration++;
      });
      _applyScreenTimeout();
      if (immersionChanged) _applySystemUi();
      unawaited(_ensureReaderFontLoaded());

      // Phase 2：上一帧视图已 detach，再 dispose；slide 再重建分页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (PageAnimMode.fromId(newMode).isHorizontalPaged && needRepaginate) {
          _splitIntoPages();
        }
      });
      return;
    }

    setState(() => _settings = newSettings);
    _applyScreenTimeout();
    if (immersionChanged) _applySystemUi();
    unawaited(_ensureReaderFontLoaded());
    if (needRepaginate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isHorizontalPaged) _splitIntoPages();
      });
    }
  }

  void _saveProgress() {
    if (_bookProvider == null) return;
    final progress = (_currentIndex + 1) / widget.allChapters.length;
    final currentChapter = widget.allChapters[_currentIndex].title;
    final chapterPosition = _currentChapterPosition();
    _progressPort.updateProgress(
      widget.book.id,
      progress,
      currentChapter,
      pageIndex: chapterPosition,
      durChapterIndex: _currentIndex,
    );
  }

  int _currentChapterPosition() {
    if (!_isHorizontalPaged || _pageSlices.isEmpty) return 0;
    return ReadingPositionMapper.chapterPositionForPage([
      for (final page in _pageSlices)
        ReadingPageRange(text: page.text, start: page.start, end: page.end),
    ], _pageIndex);
  }

  Future<void> _goToChapter(
    int index, {
    int? pageIndex,
    int? chapterPos,
    bool preserveContinuousReading = false,
  }) async {
    if (index < 0 || index >= widget.allChapters.length) return;
    if (!preserveContinuousReading) {
      _cancelContinuousReading();
    }
    if (_simRead.enabled && index > _maxReadableIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模拟追读：今日最多读到第 ${_maxReadableIndex + 1} 章')),
      );
      return;
    }
    _flushReadingSession();
    _saveProgress();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() {
      _pages = [];
      _pageIndex = 0;
      _currentIndex = index;
      if (chapterPos != null && chapterPos >= 0) {
        _pendingChapterPos = chapterPos;
        _pendingTargetPage = null;
      } else if (pageIndex != null && pageIndex >= 0) {
        _pendingTargetPage = pageIndex;
        _pendingChapterPos = null;
      }
    });
    await _loadContent();
    // 勿在此 _keepChromeAlive：翻页/点右侧下一页切章时会误弹出菜单（含「设置」入口）
  }

  void _syncPreload() {
    final source = _sourceAccessPort.sourceForBook(widget.book);
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
    // 对齐 Legado：目录秒开，不在此等待联网 / 扫盘
    final currentChapters = _chapterListPort.currentChaptersFor(widget.book);
    final chapters = currentChapters.isNotEmpty
        ? currentChapters
        : widget.allChapters;
    if (!mounted) return;
    final current = widget.allChapters[_currentIndex];
    final tocChapters = _simRead.enabled ? _readableChapters : chapters;
    await TocSheet.show(
      context,
      chapters: tocChapters,
      currentChapter: current.title,
      currentChapterId: current.id,
      bookId: widget.book.id,
      onChapterTap: (chapter, {int? pageIndex, int? chapterPos}) {
        final idx = widget.allChapters.indexWhere((c) => c.id == chapter.id);
        if (idx >= 0) {
          _goToChapter(idx, pageIndex: pageIndex, chapterPos: chapterPos);
        } else {
          final byUrl = widget.allChapters.indexWhere(
            (c) => c.url == chapter.url,
          );
          if (byUrl >= 0) {
            _goToChapter(byUrl, pageIndex: pageIndex, chapterPos: chapterPos);
          }
        }
      },
    );
  }

  Future<void> _showBookPageAnimConfig() async {
    const labels = ['默认', '覆盖', '滑动', '仿真', '滚动', '无'];
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('翻页动画'),
        children: [
          RadioGroup<int>(
            groupValue: (_bookPageAnim ?? -1) + 1,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < labels.length; i++)
                  RadioListTile<int>(title: Text(labels[i]), value: i),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final anim = selected - 1;
    final oldMode = _pageAnim.id;
    await _bookReaderPrefs.setPageAnim(widget.book.id, anim);
    setState(() => _bookPageAnim = anim);
    await _applyEffectivePageAnimChange(oldMode, _pageAnim.id);
  }

  Future<void> _applyEffectivePageAnimChange(
    String oldMode,
    String newMode,
  ) async {
    if (oldMode == newMode) {
      if (mounted) setState(() {});
      return;
    }
    final needRepaginate =
        PageAnimMode.fromId(newMode).isHorizontalPaged &&
        !_isLoading &&
        _content.isNotEmpty;
    setState(() {
      _pages = [];
      _pageIndex = 0;
      _modeGeneration++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (PageAnimMode.fromId(newMode).isHorizontalPaged && needRepaginate) {
        _splitIntoPages();
      }
    });
  }

  Future<void> _pullCloudProgress() async {
    final progressSync = _progressSyncPort;
    if (!await progressSync.isConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置 WebDAV')));
      return;
    }
    final localIdx = _currentIndex;
    final localPos = _currentChapterPosition();
    BookProgress? progress;
    try {
      progress = await progressSync.getBookProgress(widget.book);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拉取阅读进度失败: $e')));
      return;
    }
    if (!mounted) return;
    if (progress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('云端暂无进度')));
      return;
    }
    if (progress.durChapterIndex == localIdx &&
        progress.durChapterPos == localPos) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已是最新进度')));
      return;
    }
    if (progress.isBehind(chapterIndex: localIdx, chapterPos: localPos)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('获取云端进度'),
          content: const Text('当前进度超过云端进度，是否同步？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _applyCloudProgress(progress);
  }

  Future<void> _applyCloudProgress(BookProgress progress) async {
    final maxIdx = widget.allChapters.isEmpty
        ? 0
        : widget.allChapters.length - 1;
    if (progress.durChapterIndex > maxIdx) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('云端章节超出本地目录')));
      }
      return;
    }
    final idx = progress.durChapterIndex.clamp(0, maxIdx);
    if (idx != _currentIndex) {
      _goToChapter(idx, chapterPos: progress.durChapterPos);
    } else {
      _pendingChapterPos = progress.durChapterPos;
      _pendingTargetPage = null;
      _saveProgress();
      await _loadContent();
    }
    if (!mounted) return;
    final title = progress.durChapterTitle;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title == null || title.isEmpty ? '已同步最新阅读进度' : '已同步最新阅读进度：$title',
        ),
      ),
    );
  }

  /// 对齐 ReadBook.syncProgress：本地更快则上传，云端更快则询问应用
  Future<void> _syncReadingProgress() async {
    final progressSync = _progressSyncPort;
    if (!await progressSync.isConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置 WebDAV')));
      return;
    }
    final localIdx = _currentIndex;
    final localPos = _currentChapterPosition();
    final chapter = widget.allChapters[_currentIndex];
    BookProgress? progress;
    try {
      progress = await progressSync.getBookProgress(widget.book);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拉取阅读进度失败: $e')));
      return;
    }
    if (!mounted) return;
    if (progress == null ||
        progress.isBehind(chapterIndex: localIdx, chapterPos: localPos)) {
      try {
        await progressSync.uploadBookProgress(
          BookProgressFactory.fromBook(
            widget.book,
            durChapterIndex: localIdx,
            durChapterPos: localPos,
            durChapterTitle: chapter.title,
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('上传成功')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('上传失败: $e')));
      }
      return;
    }
    if (progress.isAheadOf(chapterIndex: localIdx, chapterPos: localPos)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('获取云端进度'),
          content: Text(
            '发现云端更新进度：${progress!.durChapterTitle ?? '第${progress.durChapterIndex + 1}章'}，是否同步？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) await _applyCloudProgress(progress);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('进度已同步')));
    }
  }

  Future<void> _coverCloudProgress() async {
    final progressSync = _progressSyncPort;
    if (!await progressSync.isConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置 WebDAV')));
      return;
    }
    final chapter = widget.allChapters[_currentIndex];
    try {
      await progressSync.uploadBookProgress(
        BookProgressFactory.fromBook(
          widget.book,
          durChapterIndex: _currentIndex,
          durChapterPos: _currentChapterPosition(),
          durChapterTitle: chapter.title,
        ),
        toast: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('上传成功')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('上传失败: $e')));
    }
  }

  Future<void> _reverseContent() async {
    final chapter = widget.allChapters[_currentIndex];
    final ok = await ReadBook.instance.reverseChapterContent(
      chapter: chapter,
      bookId: widget.book.id,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前章节无缓存，无法反转')));
      return;
    }
    await _loadContent();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已反转本章内容')));
    }
  }

  Future<void> _toggleReSegment() async {
    final next = !_reSegment;
    setState(() => _reSegment = next);
    ReadBook.instance.reSegment = next;
    await _bookReaderPrefs.setReSegment(widget.book.id, next);
    final chapter = widget.allChapters[_currentIndex];
    ReadBook.instance.invalidateMemoryCache(chapter.id, bookId: widget.book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(next ? '已开启重新分段' : '已关闭重新分段')));
    await _loadContent();
  }

  Future<void> _openContentEdit() async {
    final chapter = widget.allChapters[_currentIndex];
    final bid = widget.book.id;
    final readBook = ReadBook.instance;
    var initial =
        await readBook.readRawChapterCache(chapter.id, bookId: bid) ?? '';
    if (initial.isEmpty) {
      initial = _content;
    }
    if (!mounted) return;
    await ContentEditDialog.show(
      context,
      bookId: bid,
      chapter: chapter,
      initialContent: initial,
      loadRawContent: ({bool reset = false}) async {
        if (reset) {
          await readBook.invalidateChapterCache(chapter.id, bookId: bid);
          final raw = await _contentRefetchPort.fetchRawContent(
            book: widget.book,
            chapter: chapter,
          );
          if (!ReadBook.shouldSkipCache(raw)) {
            await readBook.writeRawChapterCache(chapter.id, raw, bookId: bid);
          }
          return raw;
        }
        return await readBook.readRawChapterCache(chapter.id, bookId: bid) ??
            '';
      },
      onSaved: (content) async {
        await ReadBook.instance.saveEditedContent(
          chapter: chapter,
          content: content,
          bookId: bid,
        );
        if (mounted) await _loadContent();
      },
    );
  }

  Future<void> _toggleReplacePurify() async {
    final next = !_enableReplace;
    setState(() => _enableReplace = next);
    ReadBook.instance.enableReplace = next;
    await _readerSessionPrefs.saveEnableReplace(next);
    final chapter = widget.allChapters[_currentIndex];
    ReadBook.instance.invalidateMemoryCache(chapter.id, bookId: widget.book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(next ? '已开启替换净化' : '已关闭替换净化')));
    await _loadContent();
  }

  Future<void> _updateToc() async {
    final source = _sourceAccessPort.sourceForBook(widget.book);
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未找到书源，无法更新目录')));
      }
      return;
    }

    final currentChapter = widget.allChapters[_currentIndex];
    final currentId = currentChapter.id;
    final currentTitle = currentChapter.title;
    _saveProgress();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在更新目录…'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    List<Chapter> newChapters;
    try {
      newChapters = await _chapterRefreshPort.refreshChapters(
        widget.book,
        source: source,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新目录失败: $e')));
      }
      return;
    }

    if (!mounted) return;
    if (newChapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目录为空')));
      return;
    }

    var newIndex = newChapters.indexWhere((c) => c.id == currentId);
    if (newIndex < 0) {
      newIndex = newChapters.indexWhere((c) => c.title == currentTitle);
    }
    if (newIndex < 0) {
      newIndex = _currentIndex.clamp(0, newChapters.length - 1);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('目录已更新，共 ${newChapters.length} 章')));

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: widget.book,
          chapter: newChapters[newIndex],
          allChapters: List<Chapter>.from(newChapters),
        ),
      ),
    );
  }

  Future<void> _openOfflineCache() async {
    final downloadState = _cacheDownloadPort.state;
    if (downloadState.isDownloading) {
      if (downloadState.downloadBookId == widget.book.id) {
        _cacheDownloadPort.cancelDownload();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已停止缓存')));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('正在缓存其他书籍')));
      }
      return;
    }

    final source = _sourceAccessPort.sourceForBook(widget.book);
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未找到书源，无法缓存')));
      }
      return;
    }

    var chapters = List<Chapter>.from(widget.allChapters);
    if (chapters.isEmpty) {
      chapters = await _cacheDownloadPort.loadChapters(
        widget.book,
        source: source,
      );
      if (!mounted) return;
    }
    if (chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目录为空')));
      }
      return;
    }

    final cachedIds = await _contentCache.listChapterIds(widget.book.id);
    final cachedCount = chapters
        .where(
          (c) =>
              c.isDownloaded ||
              cachedIds.contains(_contentCache.sanitizeChapterId(c.id)),
        )
        .length;

    if (!mounted) return;
    final choice = await DownloadChoiceDialog.show(
      context,
      currentChapterIndex: _currentIndex.clamp(0, chapters.length - 1),
      totalChapters: chapters.length,
      cachedCount: cachedCount,
    );
    if (choice == null || !mounted) return;

    final toDownload = filterChaptersForDownload(
      chapters,
      choice,
      startIndex: _currentIndex,
      cachedIds: cachedIds,
      sanitizeChapterId: _contentCache.sanitizeChapterId,
    );
    if (toDownload.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有需要缓存的章节')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('开始缓存 ${toDownload.length} 章…')));
    await _cacheDownloadPort.downloadAllChapters(
      widget.book.id,
      toDownload,
      source,
      concurrency: choice.concurrency,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '缓存完成 ${_cacheDownloadPort.state.completed}/${toDownload.length}',
          ),
        ),
      );
    }
  }

  Future<void> _refreshChapter() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在刷新本章…'), duration: Duration(seconds: 1)),
    );
    await _loadContent(forceRefresh: true);
  }

  Future<void> _addBookmark() async {
    if (!_bookmarkReadinessPort.isReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('引擎未就绪，无法添加书签')));
      return;
    }
    final chapter = widget.allChapters[_currentIndex];
    final snippet = _isHorizontalPaged && _pages.isNotEmpty
        ? _pages[_pageIndex].trim()
        : _content.trim();
    final preview = snippet.length > 80
        ? '${snippet.substring(0, 80)}…'
        : snippet;
    final chapterPos = _isHorizontalPaged && _pages.isNotEmpty
        ? _pageSlices[_pageIndex].start
        : chapterPosForScrollOffset(
            offset: _scrollController.hasClients ? _scrollController.offset : 0,
            maxScrollExtent: _scrollController.hasClients
                ? _scrollController.position.maxScrollExtent
                : 0,
            contentLength: _displayContentWithoutHardPageBreaks.length,
          );
    final saved = await showBookmarkEditorSheet(
      context,
      book: widget.book,
      chapterTitle: chapter.title,
      chapterIndex: _currentIndex,
      chapterPos: chapterPos,
      bookText: preview.isEmpty ? chapter.title : preview,
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已添加书签')));
  }

  Future<void> _copyContent() async {
    final text = _isHorizontalPaged && _pages.isNotEmpty
        ? _pages[_pageIndex]
        : _content;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制本章/本页内容')));
  }

  Future<void> _openChangeSource() async {
    final result = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => ChangeSourcePage(book: widget.book)),
    );
    if (result == null || !mounted) return;
    final chapters = _chapterListPort.currentChaptersFor(widget.book);
    if (chapters.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已换源，但目录为空，请返回详情重试')));
      return;
    }
    final idx = _currentIndex.clamp(0, chapters.length - 1);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: result,
          chapter: chapters[idx],
          allChapters: List<Chapter>.from(chapters),
        ),
      ),
    );
  }

  Future<void> _autoChangeSource() async {
    final sources = _sourceAccessPort.availableSources;
    if (sources.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可用书源，无法自动换源')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('正在自动寻找可用书源…')));
    final updated = await _sourceAccessPort.autoChangeSource(
      widget.book,
      sources: sources,
    );
    if (!mounted) return;
    final chapters = _chapterListPort.currentChaptersFor(widget.book);
    if (updated == null || chapters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有找到可用书源')));
      return;
    }
    final index = _currentIndex.clamp(0, chapters.length - 1);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: updated,
          chapter: chapters[index],
          allChapters: List<Chapter>.from(chapters),
        ),
      ),
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
        _showInterfacePanel();
      case 'ai':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiChatPage(isStandalone: false),
          ),
        );
      case 'change_source':
        unawaited(_openChangeSource());
      case 'auto_change_source':
        unawaited(_autoChangeSource());
      case 'refresh':
        _refreshChapter();
      case 'bookmark':
        _addBookmark();
      case 'copy':
        _copyContent();
      case 'book_info':
        _openBookInfo();
      case 'cache':
        unawaited(_openOfflineCache());
      case 'page_anim':
        unawaited(_showBookPageAnimConfig());
      case 'cloud_progress':
        unawaited(_pullCloudProgress());
      case 'cover_progress':
        unawaited(_coverCloudProgress());
      case 'reverse':
        unawaited(_reverseContent());
      case 'replace':
        unawaited(_toggleReplacePurify());
      case 'resegment':
        unawaited(_toggleReSegment());
      case 'edit_content':
        unawaited(_openContentEdit());
      case 'update_toc':
        unawaited(_updateToc());
      case 'tts':
        unawaited(_openAudioPlayPage());
      case 'manga':
        unawaited(_openMangaReader());
      case 'auto_read':
        _openAutoReadPanel();
      case 'search_content':
        unawaited(_openContentSearch());
      case 'simulated_reading':
        unawaited(_openSimulatedReading());
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
      item('auto_change_source', Icons.autorenew, '自动换源'),
      item('refresh', Icons.refresh, '刷新'),
      item('cache', Icons.download_outlined, '离线缓存'),
      const PopupMenuDivider(),
      item('toc', Icons.list_alt, '目录'),
      item('bookmark', Icons.bookmark_add_outlined, '书签'),
      item('search_content', Icons.find_in_page_outlined, '全文搜索'),
      item('copy', Icons.copy_outlined, '拷贝内容'),
      item('settings', Icons.text_fields, '界面'),
      item('ai', Icons.smart_toy_outlined, 'AI 助手'),
      const PopupMenuDivider(),
      item('page_anim', Icons.animation, '翻页动画(本书)'),
      item('cloud_progress', Icons.cloud_download_outlined, '拉取云端进度'),
      item('cover_progress', Icons.cloud_upload_outlined, '覆盖云端进度'),
      item('reverse', Icons.swap_vert, '反转内容'),
      item('replace', Icons.find_replace, '替换净化开关'),
      PopupMenuItem(
        value: 'resegment',
        child: ListTile(
          leading: Icon(
            _reSegment ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
          ),
          title: const Text('重新分段', style: TextStyle(fontSize: 14)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      item('edit_content', Icons.edit_note_outlined, '编辑内容'),
      item('update_toc', Icons.toc, '更新目录'),
      item('simulated_reading', Icons.calendar_today_outlined, '模拟追读'),
      item('book_info', Icons.info_outline, '书籍信息'),
      const PopupMenuDivider(),
      item('tts', Icons.record_voice_over_outlined, '朗读'),
      item('manga', Icons.auto_stories_outlined, '漫画阅读'),
      item('auto_read', Icons.speed, '自动阅读'),
      item('click_zone', Icons.grid_on, '点击区域设置'),
      item('more_settings', Icons.settings, '设置'),
      item('page_key', Icons.keyboard, '自定义翻页键'),
    ];
  }

  /// 始终挂在树上，用透明度显隐；桌面端整页已 ExcludeSemantics，
  /// 这里再包一层避免 chrome 切显隐时额外撕语义节点。
  Widget _chromeLayer({required Widget child}) {
    return ExcludeSemantics(
      child: IgnorePointer(
        ignoring: !_chromeVisible,
        child: Opacity(opacity: _chromeVisible ? 1 : 0, child: child),
      ),
    );
  }

  // TODO(refactor): 顶/底 chrome 与更多菜单拆到 reader_chrome.dart。
  Widget _buildTopChrome(ReaderTheme theme) {
    final chapter = widget.allChapters[_currentIndex];
    final sourceName = _sourceDisplayName;
    final chapterUrl = _chapterUrlLabel;
    final iconBtnStyle = IconButton.styleFrom(
      foregroundColor: theme.text,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(40, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Material(
      elevation: 4,
      color: theme.appBar.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row1: 返回 | 书名 | 换源 | 刷新 | 缓存 | ⋮
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: '返回',
                      onPressed: () {
                        _saveProgress();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _openBookInfo,
                        child: Text(
                          widget.book.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: '换源',
                      onPressed: _openChangeSource,
                    ),
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.refresh),
                      tooltip: '刷新',
                      onPressed: () => unawaited(_refreshChapter()),
                    ),
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.download_outlined),
                      tooltip: '离线缓存',
                      onPressed: () => unawaited(_openOfflineCache()),
                    ),
                    PopupMenuButton<String>(
                      offset: legadoAppBarPopupOffset(context),
                      icon: Icon(Icons.more_vert, color: theme.text),
                      tooltip: '更多',
                      onSelected: _onMenuSelected,
                      itemBuilder: (_) => _menuItems(),
                    ),
                  ],
                ),
              ),
              // Row2: 章节名 | 书源芯片
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: theme.text),
                      ),
                    ),
                    if (sourceName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: _chromeAccent,
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          onTap: _openChangeSource,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                sourceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Row3: 章节 URL
              if (chapterUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                  child: Text(
                    chapterUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.text.withValues(alpha: 0.45),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 章首/章尾书票（流式插入，不遮挡正文；无独立 prefs 时默认启用）
  Widget _buildBookplate({required bool isHeader, required Color textColor}) {
    return BookplateOverlay(
      book: widget.book,
      currentChapterIndex: _currentIndex,
      totalChapters: widget.allChapters.length,
      textColor: textColor,
      isHeader: isHeader,
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

  /// 全书阅读进度 0~1（含章内页占比）
  double get _readingProgress {
    final total = widget.allChapters.length;
    if (total <= 0) return 0;
    if (_isHorizontalPaged && _pages.isNotEmpty) {
      return (_currentIndex + (_pageIndex + 1) / _pages.length) / total;
    }
    return (_currentIndex + 1) / total;
  }

  /// 页脚（对齐 legado）：章名 | 页码  全书进度%
  Widget _buildPageFooter(Chapter chapter, ReaderTheme theme) {
    final muted = theme.text.withValues(alpha: 0.45);
    final style = TextStyle(fontSize: 11, color: muted);
    final pageLabel = _isHorizontalPaged && _pages.isNotEmpty
        ? '${_pageIndex + 1}/${_pages.length}'
        : '1/1';
    final pct = (_readingProgress * 100).toStringAsFixed(1);
    final hPad = _settings.paddingHorizontal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          thickness: 0.5,
          color: theme.text.withValues(alpha: 0.12),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              const SizedBox(width: 8),
              Text('$pageLabel  $pct%', style: style),
            ],
          ),
        ),
      ],
    );
  }

  /// UI-1 底栏（对齐 legado）：圆钮行 · 上下章+进度 · 目录/朗读/界面/设置
  Widget _buildBottomChrome(ReaderTheme theme) {
    final hasPages = _isHorizontalPaged && _pages.length > 1;
    final sliderMax = hasPages
        ? (_pages.length - 1).toDouble()
        : (widget.allChapters.length > 1
              ? (widget.allChapters.length - 1).toDouble()
              : 1.0);
    final double sliderValue = hasPages
        ? _pageIndex.toDouble().clamp(0.0, sliderMax).toDouble()
        : _currentIndex.toDouble().clamp(0.0, sliderMax).toDouble();
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < _maxReadableIndex;

    return Material(
      elevation: 8,
      color: theme.appBar.withValues(alpha: 0.97),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 圆钮：搜索 | 原网页 | 自动翻页 | 亮度
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chromeRoundButton(
                      theme,
                      Icons.search,
                      '搜索',
                      () => unawaited(_openContentSearch()),
                    ),
                    _chromeRoundButton(
                      theme,
                      Icons.open_in_new,
                      '原网页',
                      () => unawaited(_openChapterInBrowser()),
                    ),
                    _chromeRoundButton(
                      theme,
                      Icons.autorenew,
                      '自动翻页',
                      _openAutoReadPanel,
                    ),
                    _chromeRoundButton(
                      theme,
                      Icons.wb_sunny_outlined,
                      '亮度',
                      _showBrightnessSheet,
                    ),
                  ],
                ),
              ),
              // 上一章 | 进度滑块 | 下一章
              Row(
                children: [
                  TextButton(
                    onPressed: canPrev
                        ? () => _goToChapter(_currentIndex - 1)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.text,
                      disabledForegroundColor: theme.text.withValues(
                        alpha: 0.3,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('上一章', style: TextStyle(fontSize: 14)),
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
                        activeTrackColor: _chromeAccent.withValues(alpha: 0.55),
                        inactiveTrackColor: theme.text.withValues(alpha: 0.12),
                        thumbColor: _chromeAccent,
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
                            if (target != _pageIndex) {
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
                  TextButton(
                    onPressed: canNext
                        ? () => _goToChapter(_currentIndex + 1)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.text,
                      disabledForegroundColor: theme.text.withValues(
                        alpha: 0.3,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('下一章', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              // 底栏主入口：目录 | 朗读 | 界面 | 设置
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chromeNavItem(
                      theme,
                      icon: Icons.format_list_bulleted,
                      label: '目录',
                      onTap: _showTocSheet,
                    ),
                    _chromeNavItem(
                      theme,
                      icon: Icons.headphones,
                      label: '朗读',
                      onTap: _openAudioPlayPage,
                      onLongPress: _openTtsPanel,
                    ),
                    _chromeNavItem(
                      theme,
                      label: '界面',
                      onTap: _showInterfacePanel,
                      aaLabel: true,
                    ),
                    _chromeNavItem(
                      theme,
                      icon: Icons.settings,
                      label: '设置',
                      onTap: _openMoreSettingsPanel,
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

  Widget _chromeRoundButton(
    ReaderTheme theme,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    final fill = theme.text.withValues(alpha: 0.12);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: fill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            _keepChromeAlive();
            onTap();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: theme.text.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chromeNavItem(
    ReaderTheme theme, {
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool aaLabel = false,
  }) {
    final color = theme.text.withValues(alpha: 0.9);
    return InkWell(
      onTap: () {
        _keepChromeAlive();
        onTap();
      },
      onLongPress: onLongPress == null
          ? null
          : () {
              _keepChromeAlive();
              onLongPress();
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (aaLabel)
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.text.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChapterInBrowser() async {
    final raw = _chapterUrlLabel;
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前章节无可用网址')));
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https')))) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('章节地址不是有效的网页链接')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开原网页')));
    }
  }

  Future<void> _openReaderLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        !(uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https')))) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正文链接不是有效的网页地址')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开正文链接')));
    }
  }

  void _showBrightnessSheet() {
    _autoHideTimer?.cancel();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final s = _settings;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined),
                        const SizedBox(width: 8),
                        const Text(
                          '亮度',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('跟随系统', style: TextStyle(fontSize: 14)),
                      value: s.brightnessFollowSystem,
                      onChanged: (v) {
                        _onSettingsChanged(
                          s.copyWith(brightnessFollowSystem: v),
                        );
                        setModal(() {});
                      },
                    ),
                    if (!s.brightnessFollowSystem)
                      Row(
                        children: [
                          const Icon(Icons.brightness_low, size: 20),
                          Expanded(
                            child: Slider(
                              value: s.brightness.clamp(0.15, 1.0),
                              min: 0.15,
                              max: 1.0,
                              activeColor: _chromeAccent,
                              onChanged: (v) {
                                _onSettingsChanged(s.copyWith(brightness: v));
                                setModal(() {});
                              },
                            ),
                          ),
                          Text('${(s.brightness * 100).round()}%'),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  /// 「界面」排版面板（legado dialog_read_book_style）
  void _showInterfacePanel() {
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
          onOpenTts: () {
            unawaited(_openAudioPlayPage());
          },
          onOpenAutoRead: _openAutoReadPanel,
          onOpenClickZone: _openClickZonePanel,
          onOpenMoreSettings: _openMoreSettingsPanel,
        );
        // 独立路由须单独 ExcludeSemantics，否则仍会撞 AXTree
        final isDesktop = switch (defaultTargetPlatform) {
          TargetPlatform.windows ||
          TargetPlatform.linux ||
          TargetPlatform.macOS => true,
          _ => false,
        };
        return isDesktop ? ExcludeSemantics(child: panel) : panel;
      },
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  ReaderTheme get _currentTheme => _settings.resolveTheme();

  // TODO(refactor): 翻页模式（slide/scroll/simulation）拆到 reader_body.dart。
  @override
  Widget build(BuildContext context) {
    final chapter = widget.allChapters[_currentIndex];
    final theme = _currentTheme;

    // Key 强制按模式+代数整树重建，避免 PageView/ScrollView 元素复用导致控制器双挂
    Widget page = KeyedSubtree(
      key: ValueKey('reader-mode-${_pageAnim.id}-$_modeGeneration'),
      child: _pageAnim.id == 'scroll'
          ? _buildScrollMode(chapter, theme)
          : _buildSlideMode(chapter, theme),
    );

    // 整页排除语义：压制 Windows accessibility_bridge
    // Failed to update ui::AXTree … will not be in the tree（引擎已知缺陷）
    final isDesktop = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
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

  Widget _buildPagedText(ReaderTheme theme, String text, int pageIndex) {
    final style = _readerTextStyle(theme.text);
    final slice = _pageSlices[pageIndex];
    final content = ReaderSelectableText(
      text: text,
      style: style,
      markupDocument: _displayDocument,
      markupStart: slice.start,
      markupEnd: slice.end,
      onOpenLink: _openReaderLink,
      imageCache: _readerImageCache,
      imageSizes: _displayImageSizes(
        _readerImageMaxWidth(),
        maxHeight: _isHorizontalPaged ? _readerImageMaxHeight() : null,
      ),
      imageHeaders: _readerImageHeaders,
      textAlign: _readerTextAlign,
      onWriteNote: _openNoteEditor,
      onWriteNoteAt: _openNoteEditorAt,
      onAddBookmarkAt: _addSelectedBookmark,
      onReadAloud: _readSelectedText,
      onReadAloudAt: _readSelectedTextFromPosition,
      onDictionaryLookup: _openSelectedDictionary,
      onContentSearch: _openSelectedContentSearch,
      onOpenBrowser: _openSelectedBrowser,
      onShareText: _shareSelectedText,
      readAloudFromSelection: _selectionSpeakContinuously,
      onReadAloudModeChanged: _setSelectionSpeakMode,
    );
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _settings.paddingHorizontal,
        vertical: _settings.paddingVertical,
      ),
      child: content,
    );
    // textBottomJustify：不足一页时贴底（legado 同名开关）
    final body = _settings.textBottomJustify
        ? SizedBox.expand(
            child: Align(alignment: Alignment.bottomCenter, child: padded),
          )
        : ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(primary: false, child: padded),
          );
    // Include bg in the page itself so Cover/Slide snapshots occlude (Jingshiro).
    final path = theme.bgImagePath;
    Widget? bgImage;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        bgImage = Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (bgImage != null) Positioned.fill(child: bgImage),
        body,
      ],
    );
  }

  /// 覆盖：抵消 PageView 对下一页的位移，当前页滑走露出下层；仿真：透视旋转近似。
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

    if (paged && _pages.isNotEmpty) {
      return Stack(
        children: [
          ReaderTurnView(
            key: _turnKey,
            mode: _pageAnim,
            pageIndex: _pageIndex,
            pageCount: _pages.length,
            buildPage: (index) => _buildPagedText(theme, _pages[index], index),
            onPageChanged: (index) {
              setState(() => _pageIndex = index);
              _flushReadingSession();
              _bumpScreenTimeout();
            },
            onTurnChapterPrev: () {
              if (_currentIndex > 0) {
                _pendingTargetPage = -1;
                _goToChapter(_currentIndex - 1);
              }
            },
            onTurnChapterNext: () {
              if (_currentIndex < widget.allChapters.length - 1) {
                _pendingTargetPage = 0;
                _goToChapter(_currentIndex + 1);
              }
            },
            hasChapterPrev: _currentIndex > 0,
            hasChapterNext: _currentIndex < widget.allChapters.length - 1,
            backPageColor: theme.background,
            overlay: Positioned.fill(child: _buildClickZones()),
          ),
        ],
      );
    }

    return _wrapScrollWithClickZones(
      SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.symmetric(
          horizontal: _settings.paddingHorizontal,
          vertical: _settings.paddingVertical,
        ),
        child: ReaderSelectableText(
          text: _displayContentWithoutHardPageBreaks,
          style: _readerTextStyle(theme.text),
          markupDocument: _displayDocumentWithoutHardPageBreaks,
          onOpenLink: _openReaderLink,
          imageCache: _readerImageCache,
          imageSizes: _displayImageSizes(_readerImageMaxWidth()),
          imageHeaders: _readerImageHeaders,
          textAlign: _readerTextAlign,
          onWriteNote: _openNoteEditor,
          onWriteNoteAt: _openNoteEditorAt,
          onAddBookmarkAt: _addSelectedBookmark,
          onReadAloud: _readSelectedText,
          onReadAloudAt: _readSelectedTextFromPosition,
          onDictionaryLookup: _openSelectedDictionary,
          onContentSearch: _openSelectedContentSearch,
          onOpenBrowser: _openSelectedBrowser,
          onShareText: _shareSelectedText,
          readAloudFromSelection: _selectionSpeakContinuously,
          onReadAloudModeChanged: _setSelectionSpeakMode,
        ),
      ),
    );
  }

  Widget? _bgImageLayer(ReaderTheme theme) {
    final path = theme.bgImagePath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return Positioned.fill(
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  /// 滑动翻页模式
  Widget _buildSlideMode(Chapter chapter, ReaderTheme theme) {
    final cutout = _settings.expandIntoCutout;
    final bgImage = _bgImageLayer(theme);
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          ?bgImage,
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
                if (!_isLoading &&
                    !_isEmptyBody &&
                    (!_isHorizontalPaged || _pageIndex == 0))
                  _buildBookplate(isHeader: true, textColor: theme.text),
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
                if (!_isLoading &&
                    _content != '加载中...' &&
                    !_isEmptyBody &&
                    _isHorizontalPaged &&
                    _pages.isNotEmpty &&
                    _pageIndex == _pages.length - 1)
                  _buildBookplate(isHeader: false, textColor: theme.text),
                if (!_isLoading && _content != '加载中...' && !_isEmptyBody)
                  _buildPageFooter(chapter, theme),
              ],
            ),
          ),
          if (_autoReadRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 12,
              child: _autoReadBadge(theme),
            ),
          _chromeDismissScrim(),
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
          if (_searchMenuVisible) _buildSearchMenuOverlay(theme),
          if (_showClickRegionTip)
            Positioned.fill(
              child: ClickRegionTipOverlay(
                layout: _clickLayout,
                onDismiss: () => unawaited(_dismissClickRegionTip()),
              ),
            ),
        ],
      ),
    );
  }

  void _prevPage() {
    _cancelContinuousReading();
    _bumpScreenTimeout();
    if (_isHorizontalPaged && _pages.isNotEmpty) {
      final turn = _turnKey.currentState;
      if (turn != null) {
        unawaited(turn.turnByAnim(PageTurnDirection.prev));
      } else if (_pageIndex > 0) {
        setState(() => _pageIndex -= 1);
      } else if (_currentIndex > 0) {
        _pendingTargetPage = -1;
        _goToChapter(_currentIndex - 1);
      }
      return;
    }
    if (_currentIndex > 0) _goToChapter(_currentIndex - 1);
  }

  void _nextPage() {
    _cancelContinuousReading();
    _bumpScreenTimeout();
    if (_isHorizontalPaged && _pages.isNotEmpty) {
      final turn = _turnKey.currentState;
      if (turn != null) {
        unawaited(turn.turnByAnim(PageTurnDirection.next));
      } else if (_pageIndex < _pages.length - 1) {
        setState(() => _pageIndex += 1);
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
      final ttsPlaying = _ttsPort.state == TtsPlaybackStatePort.playing;
      if (ttsPlaying && !_settings.volumeKeyPageOnPlay) {
        return KeyEventResult.ignored;
      }
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
    final bgImage = _bgImageLayer(theme);
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          ?bgImage,
          SafeArea(
            top: !cutout,
            bottom: !cutout,
            left: !cutout,
            right: !cutout,
            child: Column(
              children: [
                Expanded(
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
                      : _wrapScrollWithClickZones(
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
                                  _buildBookplate(
                                    isHeader: true,
                                    textColor: theme.text,
                                  ),
                                  ReaderSelectableText(
                                    text: _displayContentWithoutHardPageBreaks,
                                    style: _readerTextStyle(theme.text),
                                    markupDocument:
                                        _displayDocumentWithoutHardPageBreaks,
                                    onOpenLink: _openReaderLink,
                                    imageCache: _readerImageCache,
                                    imageSizes: _displayImageSizes(
                                      _readerImageMaxWidth(),
                                    ),
                                    imageHeaders: _readerImageHeaders,
                                    textAlign: _readerTextAlign,
                                    onWriteNote: _openNoteEditor,
                                    onWriteNoteAt: _openNoteEditorAt,
                                    onAddBookmarkAt: _addSelectedBookmark,
                                    onReadAloud: _readSelectedText,
                                    onReadAloudAt:
                                        _readSelectedTextFromPosition,
                                    onDictionaryLookup: _openSelectedDictionary,
                                    onContentSearch: _openSelectedContentSearch,
                                    onOpenBrowser: _openSelectedBrowser,
                                    onShareText: _shareSelectedText,
                                    readAloudFromSelection:
                                        _selectionSpeakContinuously,
                                    onReadAloudModeChanged:
                                        _setSelectionSpeakMode,
                                  ),
                                  _buildBookplate(
                                    isHeader: false,
                                    textColor: theme.text,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                if (!_isLoading && !_isEmptyBody)
                  _buildPageFooter(chapter, theme),
              ],
            ),
          ),
          if (_autoReadRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 12,
              child: _autoReadBadge(theme),
            ),
          _chromeDismissScrim(),
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
          if (_searchMenuVisible) _buildSearchMenuOverlay(theme),
          if (_showClickRegionTip)
            Positioned.fill(
              child: ClickRegionTipOverlay(
                layout: _clickLayout,
                onDismiss: () => unawaited(_dismissClickRegionTip()),
              ),
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
