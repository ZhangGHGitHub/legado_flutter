import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../model/read_book.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../providers/book_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/note_service.dart';
import '../../services/reading_record_service.dart';
import '../../services/tts_service.dart';
import '../../utils/chinese_convert.dart';
import '../book/change_source_page.dart';
import '../book/toc_sheet.dart';
import '../book/book_info_page.dart';
import '../cache/download_choice_dialog.dart';
import '../cache/download_helpers.dart';
import '../reader/ai_chat_page.dart';
import '../../help/book_help.dart';
import '../../models/book_progress.dart';
import '../../services/book_progress_sync.dart';
import '../../services/book_reader_prefs.dart';
import '../../services/click_action_prefs.dart';
import '../../services/book_source_service.dart';
import '../../services/read_style_prefs.dart';
import '../../services/reader_session_prefs.dart';
import '../../services/simulated_reading_prefs.dart';
import 'auto_read_panel.dart';
import 'click_action_panel.dart';
import 'click_region_tip_overlay.dart';
import 'content_edit_dialog.dart';
import 'more_settings_panel.dart';
import 'reader_settings.dart';
import 'search_content_page.dart';
import 'search_content_result.dart';
import 'simulated_reading_dialog.dart';
import 'tts_panel.dart';
import 'turn/page_direction.dart';
import 'turn/reader_turn_view.dart';
import '../audio/audio_play_page.dart';
import '../manga/manga_reader_page.dart';
import '../../widgets/bookplate_overlay.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/reader_selectable_text.dart';

/// ????? ? Phase F UI-1?chrome ???? / ????? / ????
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
  String _content = '???...';
  bool _isLoading = true;
  int _currentIndex = 0;
  int _pageIndex = 0;
  int? _pendingTargetPage; // ??????????????
  List<String> _pages = [];
  late ReaderSettings _settings;
  late ScrollController _scrollController;
  final GlobalKey<ReaderTurnViewState> _turnKey = GlobalKey<ReaderTurnViewState>();
  BookProvider? _bookProvider; // ??????? dispose ? context.read ??
  DateTime? _sessionStart;
  int _sessionChars = 0;
  int _lastCountedChapterIndex = -1;

  /// UI-1: ?/? chrome ??????????????????????
  bool _chromeVisible = true;
  Timer? _autoHideTimer;
  static const _autoHideDelay = Duration(seconds: 3);

  /// ??????????? Key ????? PageView/ScrollView
  int _modeGeneration = 0;

  /// UI-2: ??????????/??????????????????
  final FocusNode _focusNode = FocusNode();

  /// UI-2: ????????
  Timer? _autoReadTimer;
  bool _autoReadRunning = false;

  /// UI-2: ??????
  final Battery _battery = Battery();
  int? _batteryLevel;
  Timer? _batteryTimer;

  /// UI-2: ?????legado screenOffTimerStart?
  Timer? _screenOffTimer;

  /// UI-2: ??????????? searchMenu ?/?????
  List<SearchContentResult> _searchResults = [];
  int _searchResultIndex = -1;
  bool _searchMenuVisible = false;
  int? _pendingSearchOccurrence; // ??? N ???

  /// UI-2: ????
  SimulatedReadingConfig _simRead = SimulatedReadingConfig(
    startDate: DateTime.now(),
  );

  /// ?????????????????
  bool _showClickRegionTip = false;

  /// ???????????????? [ReaderSessionPrefs]?
  bool _enableReplace = true;

  /// ???????null=????-1=?????0..4=????
  int? _bookPageAnim;

  /// ??????
  bool _reSegment = false;

  /// ?????????????????
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
    _applyScreenTimeout();
    _applySystemUi();
    unawaited(_loadSimulatedReading());
    unawaited(_loadReadStylePrefs());
    unawaited(_loadClickActionPrefs());
    unawaited(_loadReaderSessionPrefs());
    unawaited(_loadBookReaderPrefs());
  }

  Future<void> _loadBookReaderPrefs() async {
    final anim = await BookReaderPrefs.getPageAnim(widget.book.id);
    final reSeg = await BookReaderPrefs.getReSegment(widget.book.id);
    if (!mounted) return;
    setState(() {
      _bookPageAnim = anim ?? -1;
      _reSegment = reSeg;
    });
    ReadBook.instance.reSegment = reSeg;
  }

  Future<void> _loadReaderSessionPrefs() async {
    final prefs = await ReaderSessionPrefs.load();
    if (!mounted) return;
    setState(() => _enableReplace = prefs.enableReplace);
    ReadBook.instance.enableReplace = prefs.enableReplace;
  }

  Future<void> _loadClickActionPrefs() async {
    final layout = await ClickActionPrefs.load();
    final tipShown = await ClickActionPrefs.isTipShown();
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
    await ClickActionPrefs.markTipShown();
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
    final provider = context.read<BookProvider>();
    final book = provider.findBookById(widget.book.id) ?? widget.book;
    final loaded = await SimulatedReadingPrefs.loadForBook(book);
    var cfg = loaded.config;
    if (loaded.needsBookMigrate) {
      final persisted = await provider.updateSimulatedReading(
        book,
        enabled: cfg.enabled,
        startDate: SimulatedReadingConfig.formatDate(cfg.startDate),
        startChapter: cfg.startChapter,
        dailyChapters: cfg.dailyChapters,
      );
      cfg = SimulatedReadingConfig.fromBook(persisted);
      await SimulatedReadingPrefs.save(widget.book.id, cfg);
    }
    if (!mounted) return;
    setState(() => _simRead = cfg);
    if (cfg.enabled && _currentIndex > _maxReadableIndex && _maxReadableIndex >= 0) {
      _goToChapter(_maxReadableIndex);
    }
  }

  Future<void> _loadReadStylePrefs() async {
    final share = await ReadStylePrefs.loadShareLayout();
    final overrides = await ReadStylePrefs.loadOverrides();
    final themeName = await ReadStylePrefs.loadThemeName();
    if (!mounted) return;
    setState(() {
      _settings = _settings.copyWith(
        shareLayout: share,
        themeOverrides: overrides,
        themeName: themeName,
      );
    });
    _applySystemUi();
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {
      // ??/??????????
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
      // ??/??????? wakelock ??
    }
  }

  /// ?? legado keepLight / screenOffTimerStart?
  /// 0 ?????????????????-1 ?????????????
  void _applyScreenTimeout({bool forceAlways = false}) {
    _screenOffTimer?.cancel();
    _screenOffTimer = null;
    final always = forceAlways ||
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

  /// ????????? hideStatusBar / hideNavigationBar???????????
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

  /// ????? ? ??? ? ??????
  String _prepareDisplayText(String raw) {
    var text = ChineseConvert.apply(raw, _settings.chineseConvert.code);
    if (_isEmptyBody ||
        text.startsWith('??') ||
        text.contains('?????') ||
        text == '???...') {
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
      final body = p.replaceFirst(RegExp(r'^[\s?]+'), '');
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
    _screenOffTimer?.cancel();
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
    _focusNode.dispose();
    super.dispose();
  }

  void _setAutoReadRunning(bool running) {
    _autoReadTimer?.cancel();
    _autoReadTimer = null;
    setState(() => _autoReadRunning = running);
    // ????? legado ?????????? keepLight ??
    _applyScreenTimeout();
    if (!running) return;
    final interval = Duration(
      milliseconds: (_settings.autoReadIntervalSec * 1000).round(),
    );
    _autoReadTimer = Timer.periodic(interval, (_) {
      if (!mounted || !_autoReadRunning) return;
      final lastIdx = _maxReadableIndex;
      final atLastPage = _isHorizontalPaged &&
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
              _simRead.enabled ? '????????????????' : '??????????????',
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
    // ??????????????????? legado vwMenuBg???????+???????
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
        unawaited(TtsService.instance.previousSentence());
      case ClickZoneAction.aloudNextParagraph:
        unawaited(TtsService.instance.nextSentence());
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
    final tts = TtsService.instance;
    final text = _pages.isNotEmpty
        ? _pages[_pageIndex.clamp(0, _pages.length - 1)]
        : _content;
    await tts.togglePlay(text);
  }

  /// ?????????? ReadView.setRect9x????? 1/3?
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
      return Expanded(
        child: Row(children: [cell(l), cell(c), cell(r)]),
      );
    }

    return Column(
      children: [
        row(_settings.clickTL, _settings.clickTC, _settings.clickTR),
        row(_settings.clickML, _settings.clickMC, _settings.clickMR),
        row(_settings.clickBL, _settings.clickBC, _settings.clickBR),
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
      onOpenAudioPlayer: _openAudioPlayPage,
    ).whenComplete(() {
      if (mounted) _scheduleAutoHide();
    });
  }

  /// UI-22????????? activity_audio_play?
  Future<void> _openAudioPlayPage() async {
    _autoHideTimer?.cancel();
    final chapters =
        _readableChapters.isNotEmpty ? _readableChapters : widget.allChapters;
    if (chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('??????????????')),
        );
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

  /// UI-23????????? activity_manga?
  Future<void> _openMangaReader() async {
    _autoHideTimer?.cancel();
    final chapters =
        _readableChapters.isNotEmpty ? _readableChapters : widget.allChapters;
    if (chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('??????????????')),
        );
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

  /// ?? legado ReadMenu.vwMenuBg????????????????????????
  Widget _chromeDismissScrim() {
    if (!_chromeVisible) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hideChrome,
      ),
    );
  }

  void _countChapterChars(String content) {
    if (content.startsWith('??') || content.contains('????????')) {
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
    // ?? inherit:false?????? textBaseline???????
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

  /// ????????????????? URL
  String get _sourceSubtitle {
    final name = _sourceDisplayName;
    if (name.isNotEmpty) return name;
    return _chapterUrlLabel;
  }

  /// ?????????????????? host?
  String get _sourceDisplayName {
    final source = context.read<SourceProvider>().findSourceForBook(widget.book);
    if (source != null && source.bookSourceName.isNotEmpty) {
      return source.bookSourceName;
    }
    final url = widget.book.bookSourceUrl.isNotEmpty
        ? widget.book.bookSourceUrl
        : widget.book.sourceUrl;
    if (url.isEmpty) return '';
    final host = Uri.tryParse(url)?.host;
    return (host != null && host.isNotEmpty) ? host : url;
  }

  /// ????????????
  String get _chapterUrlLabel {
    final chUrl = widget.allChapters[_currentIndex].url;
    if (chUrl.isNotEmpty) return chUrl;
    if (widget.book.bookSourceUrl.isNotEmpty) return widget.book.bookSourceUrl;
    return widget.book.sourceUrl;
  }

  /// ?????????? legado ??
  static const Color _chromeAccent = Color(0xFFFF6D00);

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
        content = '?? ????????';
      }
      if (mounted) {
        setState(() {
          _content = content.contains('?????')
              ? '?? ??????????\n\n$content'
              : content;
          _isLoading = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isHorizontalPaged) {
              _splitIntoPages();
            }
          });
        });
        final ok = !ReadBook.isEmptyContentPlaceholder(content) &&
            !content.contains('?????') &&
            !content.startsWith('??');
        if (ok) {
          bookProvider.markChapterDownloaded(chapter.id);
        }
        _countChapterChars(content);
        _syncPreload();
        _applyPendingSearchJump();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _content = '?? ????????\n\n????????????????\n\n??: $e';
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
      var offset = 0;
      for (var i = 0; i < _pages.length; i++) {
        final end = offset + _pages[i].length;
        if (charIdx < end || i == _pages.length - 1) {
          setState(() => _pageIndex = i);
          break;
        }
        // ???????????????????????????
        offset = end;
      }
    } else if (_scrollController.hasClients && text.isNotEmpty) {
      final max = _scrollController.position.maxScrollExtent;
      final ratio = (charIdx / text.length).clamp(0.0, 1.0);
      _scrollController.jumpTo(max * ratio);
    }
  }

  Future<void> _openContentSearch({
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
      initialQuery: results != null && results.isNotEmpty
          ? results[resultIndex.clamp(0, results.length - 1)].query
          : null,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('??????????')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???????')),
      );
      return;
    }
    unawaited(_gotoSearchResult(_searchResultIndex - 1));
  }

  void _searchNext() {
    if (!_searchMenuVisible || _searchResults.isEmpty) return;
    if (_searchResultIndex >= _searchResults.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('????????')),
      );
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
      final provider = context.read<BookProvider>();
      final book = provider.findBookById(widget.book.id) ?? widget.book;
      await provider.updateSimulatedReading(
        book,
        enabled: next.enabled,
        startDate: SimulatedReadingConfig.formatDate(next.startDate),
        startChapter: next.startChapter,
        dailyChapters: next.dailyChapters,
      );
      await SimulatedReadingPrefs.save(widget.book.id, next);
      if (!mounted) return;
      setState(() => _simRead = next);
      if (next.enabled &&
          _currentIndex > _maxReadableIndex &&
          _maxReadableIndex >= 0) {
        _goToChapter(_maxReadableIndex);
      }
      final unlocked =
          _simRead.simulatedTotalChapterNum(widget.allChapters.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.enabled ? '??????? ? ???? $unlocked ?' : '???????',
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
              tooltip: '????',
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
              tooltip: '????',
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
                      tooltip: '????',
                      icon: Icon(Icons.list_alt, color: theme.text),
                      onPressed: () => _openContentSearch(
                        results: _searchResults,
                        resultIndex: idx,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '???? $info',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.text, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      tooltip: '??',
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

  /// ????????????????? slide ???
  void _splitIntoPages() {
    if (_content.isEmpty || !mounted) return;
    if (!_isHorizontalPaged) return;
    // ?????? PageView?? _buildBodyText ??????
    if (ReadBook.isEmptyContentPlaceholder(_content)) {
      setState(() {
        _pages = [];
        _pageIndex = 0;
      });
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      // ????????????????????
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isHorizontalPaged) return;
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
    // chrome ? overlay ????????????/?????????
    final chapterTitleHeight = _settings.fontSize + 36.0;
    // ?????? + ??/?????? legado?
    const pageFooterHeight = 32.0;
    final pageHeight =
        renderBox.size.height -
        edgePadT -
        edgePadB -
        chapterTitleHeight -
        pageFooterHeight -
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

    setState(() {
      _pages = result;
      _pageIndex = clampedPage;
      _pendingTargetPage = null;
    });
    debugPrint(
      '?? ????: ${result.length} ? (??=$clampedPage, ???=$totalHeight, ??=$pageHeight)',
    );
  }

  /// ??????????????????? post-frame dispose ???
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
    final needRepaginate = PageAnimMode.fromId(newMode).isHorizontalPaged &&
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

    if (modeChanged) {
      setState(() {
        _settings = newSettings;
        _pages = [];
        _pageIndex = 0;
        _modeGeneration++;
      });
      _applyScreenTimeout();
      if (immersionChanged) _applySystemUi();

      // Phase 2??????? detach?? dispose?slide ?????
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
    if (needRepaginate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isHorizontalPaged) _splitIntoPages();
      });
    }
  }

  void _saveProgress() {
    final bp = _bookProvider;
    if (bp == null) return;
    final progress = (_currentIndex + 1) / widget.allChapters.length;
    final currentChapter = widget.allChapters[_currentIndex].title;
    final pageIdx = _isHorizontalPaged ? _pageIndex : 0;
    bp.updateProgress(
      widget.book.id,
      progress,
      currentChapter,
      pageIndex: pageIdx,
    );
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.allChapters.length) return;
    if (_simRead.enabled && index > _maxReadableIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '???????????? ${_maxReadableIndex + 1} ?',
          ),
        ),
      );
      return;
    }
    _saveProgress();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    setState(() {
      _pages = [];
      _pageIndex = 0;
      _currentIndex = index;
    });
    _loadContent();
    // ??? _keepChromeAlive???/????????????????????????
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
    // ?? Legado????????????? / ??
    final chapters = provider.currentChapters.isNotEmpty &&
            provider.currentChapters.first.bookId == widget.book.id
        ? provider.currentChapters
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

  Future<void> _showBookPageAnimConfig() async {
    const labels = ['??', '??', '??', '??', '??', '?'];
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('????'),
        children: [
          for (var i = 0; i < labels.length; i++)
            RadioListTile<int>(
              title: Text(labels[i]),
              value: i,
              groupValue: (_bookPageAnim ?? -1) + 1,
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final anim = selected - 1;
    final oldMode = _pageAnim.id;
    await BookReaderPrefs.setPageAnim(widget.book.id, anim);
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
    final needRepaginate = PageAnimMode.fromId(newMode).isHorizontalPaged &&
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
    if (!await BookProgressSync.isConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???? WebDAV')),
      );
      return;
    }
    final localIdx = _currentIndex;
    final localPos = _isHorizontalPaged ? _pageIndex : 0;
    BookProgress? progress;
    try {
      progress = await BookProgressSync.getBookProgress(widget.book);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('????????: $e')),
      );
      return;
    }
    if (!mounted) return;
    if (progress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('??????')),
      );
      return;
    }
    if (progress.durChapterIndex == localIdx &&
        progress.durChapterPos == localPos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('??????')),
      );
      return;
    }
    if (progress.isBehind(chapterIndex: localIdx, chapterPos: localPos)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('??????'),
          content: const Text('????????????????'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('??'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('??'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _applyCloudProgress(progress);
  }

  Future<void> _applyCloudProgress(BookProgress progress) async {
    final maxIdx =
        widget.allChapters.isEmpty ? 0 : widget.allChapters.length - 1;
    if (progress.durChapterIndex > maxIdx) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('??????????')),
        );
      }
      return;
    }
    final idx = progress.durChapterIndex.clamp(0, maxIdx);
    _pendingTargetPage = progress.durChapterPos;
    if (idx != _currentIndex) {
      _goToChapter(idx);
    } else {
      _saveProgress();
      await _loadContent();
      if (_isHorizontalPaged &&
          _pages.isNotEmpty &&
          progress.durChapterPos > 0) {
        final p = progress.durChapterPos.clamp(0, _pages.length - 1);
        setState(() => _pageIndex = p);
      }
    }
    if (!mounted) return;
    final title = progress.durChapterTitle;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          title == null || title.isEmpty
              ? '?????????'
              : '??????????$title',
        ),
      ),
    );
  }

  /// ?? ReadBook.syncProgress??????????????????
  Future<void> _syncReadingProgress() async {
    if (!await BookProgressSync.isConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???? WebDAV')),
      );
      return;
    }
    final localIdx = _currentIndex;
    final localPos = _isHorizontalPaged ? _pageIndex : 0;
    final chapter = widget.allChapters[_currentIndex];
    BookProgress? progress;
    try {
      progress = await BookProgressSync.getBookProgress(widget.book);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('????????: $e')),
      );
      return;
    }
    if (!mounted) return;
    if (progress == null ||
        progress.isBehind(chapterIndex: localIdx, chapterPos: localPos)) {
      try {
        await BookProgressSync.uploadBookProgress(
          BookProgress.fromBook(
            widget.book,
            durChapterIndex: localIdx,
            durChapterPos: localPos,
            durChapterTitle: chapter.title,
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('????')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('????: $e')),
        );
      }
      return;
    }
    if (progress.isAheadOf(chapterIndex: localIdx, chapterPos: localPos)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('??????'),
          content: Text(
            '?????????${progress!.durChapterTitle ?? '?${progress.durChapterIndex + 1}?'}??????',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('??'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('??'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) await _applyCloudProgress(progress);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?????')),
      );
    }
  }

  Future<void> _coverCloudProgress() async {
    if (!await BookProgressSync.isConfigured()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???? WebDAV')),
      );
      return;
    }
    final chapter = widget.allChapters[_currentIndex];
    try {
      await BookProgressSync.uploadBookProgress(
        BookProgress.fromBook(
          widget.book,
          durChapterIndex: _currentIndex,
          durChapterPos: _isHorizontalPaged ? _pageIndex : 0,
          durChapterTitle: chapter.title,
        ),
        toast: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('????')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('????: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('????????????')),
      );
      return;
    }
    await _loadContent();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???????')),
      );
    }
  }

  Future<void> _toggleReSegment() async {
    final next = !_reSegment;
    setState(() => _reSegment = next);
    ReadBook.instance.reSegment = next;
    await BookReaderPrefs.setReSegment(widget.book.id, next);
    final chapter = widget.allChapters[_currentIndex];
    ReadBook.instance.invalidateMemoryCache(chapter.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? '???????' : '???????')),
    );
    await _loadContent();
  }

  Future<void> _openContentEdit() async {
    final chapter = widget.allChapters[_currentIndex];
    final bid = widget.book.id;
    var initial = await BookHelp.getCachedContent(bid, chapter.id) ?? '';
    if (initial.isEmpty) {
      initial = _content;
    }
    if (!mounted) return;
    final sourceProvider = context.read<SourceProvider>();
    await ContentEditDialog.show(
      context,
      bookId: bid,
      chapter: chapter,
      initialContent: initial,
      loadRawContent: ({bool reset = false}) async {
        if (reset) {
          await ReadBook.instance.invalidateChapterCache(
            chapter.id,
            bookId: bid,
          );
          final source = sourceProvider.findSourceForBook(widget.book);
          if (source == null) return '';
          final svc = BookSourceService();
          final raw =
              await svc.getChapterContent(chapter.url, source: source);
          if (!ReadBook.shouldSkipCache(raw)) {
            await BookHelp.saveContent(bid, chapter.id, raw);
          }
          return raw;
        }
        return await BookHelp.getCachedContent(bid, chapter.id) ?? '';
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
    await ReaderSessionPrefs(enableReplace: next).save();
    final chapter = widget.allChapters[_currentIndex];
    ReadBook.instance.invalidateMemoryCache(chapter.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? '???????' : '???????')),
    );
    await _loadContent();
  }


  Future<void> _updateToc() async {
    final source = context.read<SourceProvider>().findSourceForBook(widget.book);
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('????????????')),
        );
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
          content: Text('???????'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final provider = context.read<BookProvider>();
    try {
      await provider.loadChapters(
        widget.book,
        source: source,
        forceRefresh: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('??????: $e')),
        );
      }
      return;
    }

    if (!mounted) return;
    final newChapters = provider.currentChapters;
    if (newChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('????')),
      );
      return;
    }

    var newIndex = newChapters.indexWhere((c) => c.id == currentId);
    if (newIndex < 0) {
      newIndex = newChapters.indexWhere((c) => c.title == currentTitle);
    }
    if (newIndex < 0) {
      newIndex = _currentIndex.clamp(0, newChapters.length - 1);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('??????? ${newChapters.length} ?')),
    );

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
    final provider = context.read<BookProvider>();
    if (provider.isDownloading) {
      if (provider.downloadBookId == widget.book.id) {
        provider.cancelDownload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('?????')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('????????')),
        );
      }
      return;
    }

    final source = context.read<SourceProvider>().findSourceForBook(widget.book);
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('??????????')),
        );
      }
      return;
    }

    var chapters = List<Chapter>.from(widget.allChapters);
    if (chapters.isEmpty) {
      await provider.loadChapters(widget.book, source: source);
      if (!mounted) return;
      chapters = List<Chapter>.from(provider.currentChapters);
    }
    if (chapters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('????')),
        );
      }
      return;
    }

    final cachedIds = await BookHelp.listCachedChapterIds(widget.book.id);
    final cachedCount = chapters
        .where(
          (c) =>
              c.isDownloaded ||
              cachedIds.contains(BookHelp.sanitizeId(c.id)),
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
    );
    if (toDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?????????')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('???? ${toDownload.length} ??')),
    );
    await provider.downloadAllChapters(
      widget.book.id,
      toDownload,
      source,
      concurrency: choice.concurrency,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '???? ${provider.downloadCompleted}/${toDownload.length}',
          ),
        ),
      );
    }
  }

  Future<void> _refreshChapter() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('???????'), duration: Duration(seconds: 1)),
    );
    await _loadContent(forceRefresh: true);
  }

  Future<void> _addBookmark() async {
    if (!NoteService.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('????????????')),
      );
      return;
    }
    final chapter = widget.allChapters[_currentIndex];
    final snippet = _isHorizontalPaged && _pages.isNotEmpty
        ? _pages[_pageIndex].trim()
        : _content.trim();
    final preview = snippet.length > 80 ? '${snippet.substring(0, 80)}?' : snippet;
    final pageHint = _isHorizontalPaged && _pages.isNotEmpty
        ? '?${_pageIndex + 1}/${_pages.length}?'
        : '????';
    NoteService.save(
      id: const Uuid().v4(),
      bookId: widget.book.id,
      chapterTitle: chapter.title,
      selectedText: preview.isEmpty ? chapter.title : preview,
      noteContent: '?? ? $pageHint',
      position: _currentIndex,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('?????')),
    );
  }

  Future<void> _copyContent() async {
    final text = _isHorizontalPaged && _pages.isNotEmpty
        ? _pages[_pageIndex]
        : _content;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('?????/????')),
    );
  }

  Future<void> _openChangeSource() async {
    final result = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => ChangeSourcePage(book: widget.book)),
    );
    if (result == null || !mounted) return;
    final provider = context.read<BookProvider>();
    final chapters = provider.currentChapters;
    if (chapters.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?????????????????')),
      );
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
      item('change_source', Icons.swap_horiz, '??'),
      item('refresh', Icons.refresh, '??'),
      item('cache', Icons.download_outlined, '????'),
      const PopupMenuDivider(),
      item('toc', Icons.list_alt, '??'),
      item('bookmark', Icons.bookmark_add_outlined, '??'),
      item('search_content', Icons.find_in_page_outlined, '????'),
      item('copy', Icons.copy_outlined, '????'),
      item('settings', Icons.text_fields, '??'),
      item('ai', Icons.smart_toy_outlined, 'AI ??'),
      const PopupMenuDivider(),
      item('page_anim', Icons.animation, '????(??)'),
      item('cloud_progress', Icons.cloud_download_outlined, '??????'),
      item('cover_progress', Icons.cloud_upload_outlined, '??????'),
      item('reverse', Icons.swap_vert, '????'),
      item('replace', Icons.find_replace, '??????'),
      PopupMenuItem(
        value: 'resegment',
        child: ListTile(
          leading: Icon(
            _reSegment ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
          ),
          title: const Text('????', style: TextStyle(fontSize: 14)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      item('edit_content', Icons.edit_note_outlined, '????'),
      item('update_toc', Icons.toc, '????'),
      item('simulated_reading', Icons.calendar_today_outlined, '????'),
      item('book_info', Icons.info_outline, '????'),
      const PopupMenuDivider(),
      item('tts', Icons.record_voice_over_outlined, '??'),
      item('manga', Icons.auto_stories_outlined, '????'),
      item('auto_read', Icons.speed, '????'),
      item('click_zone', Icons.grid_on, '??????'),
      item('more_settings', Icons.settings, '??'),
      item('page_key', Icons.keyboard, '??????'),
    ];
  }

  /// ???????????????????? ExcludeSemantics?
  /// ???????? chrome ????????????
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
              // Row1: ?? | ?? | ?? | ?? | ?? | ?
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: '??',
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
                      tooltip: '??',
                      onPressed: _openChangeSource,
                    ),
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.refresh),
                      tooltip: '??',
                      onPressed: () => unawaited(_refreshChapter()),
                    ),
                    IconButton(
                      style: iconBtnStyle,
                      icon: const Icon(Icons.download_outlined),
                      tooltip: '????',
                      onPressed: () => unawaited(_openOfflineCache()),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: theme.text),
                      tooltip: '??',
                      onSelected: _onMenuSelected,
                      itemBuilder: (_) => _menuItems(),
                    ),
                  ],
                ),
              ),
              // Row2: ??? | ????
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
              // Row3: ?? URL
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

  /// ??/??????????????????? prefs ??????
  Widget _buildBookplate({required bool isHeader, required Color textColor}) {
    return BookplateOverlay(
      book: widget.book,
      currentChapterIndex: _currentIndex,
      totalChapters: widget.allChapters.length,
      textColor: textColor,
      isHeader: isHeader,
    );
  }

  /// ?????? + ??????????????
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

  /// ?????? 0~1????????
  double get _readingProgress {
    final total = widget.allChapters.length;
    if (total <= 0) return 0;
    if (_isHorizontalPaged && _pages.isNotEmpty) {
      return (_currentIndex + (_pageIndex + 1) / _pages.length) / total;
    }
    return (_currentIndex + 1) / total;
  }

  /// ????? legado???? | ??  ????%
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

  /// UI-1 ????? legado????? ? ???+?? ? ??/??/??/??
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
              // ????? | ??? | ???? | ??
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chromeRoundButton(
                      theme,
                      Icons.search,
                      '??',
                      () => unawaited(_openContentSearch()),
                    ),
                    _chromeRoundButton(
                      theme,
                      Icons.open_in_new,
                      '???',
                      () => unawaited(_openChapterInBrowser()),
                    ),
                    _chromeRoundButton(
                      theme,
                      Icons.autorenew,
                      '????',
                      _openAutoReadPanel,
                    ),
                    _chromeRoundButton(
                      theme,
                      Icons.wb_sunny_outlined,
                      '??',
                      _showBrightnessSheet,
                    ),
                  ],
                ),
              ),
              // ??? | ???? | ???
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
                    child: const Text('???', style: TextStyle(fontSize: 14)),
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
                    child: const Text('???', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              // ???????? | ?? | ?? | ??
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _chromeNavItem(
                      theme,
                      icon: Icons.format_list_bulleted,
                      label: '??',
                      onTap: _showTocSheet,
                    ),
                    _chromeNavItem(
                      theme,
                      icon: Icons.headphones,
                      label: '??',
                      onTap: _openAudioPlayPage,
                      onLongPress: _openTtsPanel,
                    ),
                    _chromeNavItem(
                      theme,
                      label: '??',
                      onTap: _showInterfacePanel,
                      aaLabel: true,
                    ),
                    _chromeNavItem(
                      theme,
                      icon: Icons.settings,
                      label: '??',
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
            child: Icon(icon, size: 22, color: theme.text.withValues(alpha: 0.9)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?????????')),
      );
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https')))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?????????????')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???????')),
      );
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
                          '??',
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
                      title: const Text('????', style: TextStyle(fontSize: 14)),
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

  /// ?????????legado dialog_read_book_style?
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
        // ??????? ExcludeSemantics?????? AXTree
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
      _settings.resolveTheme();

  @override
  Widget build(BuildContext context) {
    final chapter = widget.allChapters[_currentIndex];
    final theme = _currentTheme;

    // Key ?????+????????? PageView/ScrollView ???????????
    Widget page = KeyedSubtree(
      key: ValueKey('reader-mode-${_pageAnim.id}-$_modeGeneration'),
      child: _pageAnim.id == 'scroll'
          ? _buildScrollMode(chapter, theme)
          : _buildSlideMode(chapter, theme),
    );

    // ????????? Windows accessibility_bridge
    // Failed to update ui::AXTree ? will not be in the tree????????
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

    // UI-2????????????????????????????
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

  Widget _buildPagedText(ReaderTheme theme, String text) {
    final content = ReaderSelectableText(
      text: text,
      style: _readerTextStyle(theme.text),
      textAlign: _readerTextAlign,
      onWriteNote: _openNoteEditor,
    );
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _settings.paddingHorizontal,
        vertical: _settings.paddingVertical,
      ),
      child: content,
    );
    // textBottomJustify?????????legado ?????
    if (_settings.textBottomJustify) {
      return SizedBox.expand(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: padded,
        ),
      );
    }
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        primary: false,
        child: padded,
      ),
    );
  }

  /// ????? PageView ????????????????????????????
  /// ??????? PageView???????????????????+???
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
                  '??????',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.text.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '????????????????????????',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.text.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _refreshChapter,
                  child: const Text('????'),
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
            buildPage: (index) => _buildPagedText(theme, _pages[index]),
            onPageChanged: (index) {
              setState(() => _pageIndex = index);
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
            overlay: Positioned.fill(child: _buildClickZones()),
          ),
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

  /// ??????
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
                if (_isLoading && _content != '???...')
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
                  child: _isLoading && _content == '???...'
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: theme.text),
                              const SizedBox(height: 16),
                              Text(
                                '???...',
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
                    _content != '???...' &&
                    !_isEmptyBody &&
                    _isHorizontalPaged &&
                    _pages.isNotEmpty &&
                    _pageIndex == _pages.length - 1)
                  _buildBookplate(isHeader: false, textColor: theme.text),
                if (!_isLoading && _content != '???...' && !_isEmptyBody)
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
          // ?? overlay???????? AXTree remount?
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _chromeLayer(child: _buildTopChrome(theme)),
          ),
          // ?? overlay
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
      final ttsPlaying = TtsService.instance.state == TtsPlaybackState.playing;
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

  /// ??????
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
                                '???...',
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
                            // ?? AnimatedSwitcher?????? ScrollView ?????
                            // ??? _scrollController??? dual ScrollPosition ??
                            NotificationListener<ScrollNotification>(
                              key: ValueKey('scroll_$_currentIndex'),
                              onNotification: (notification) {
                                if (notification is ScrollEndNotification) {
                                  final pixels =
                                      _scrollController.position.pixels;
                                  final maxExt = _scrollController
                                      .position.maxScrollExtent;
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildChapterHeader(chapter, theme),
                                    _buildBookplate(
                                      isHeader: true,
                                      textColor: theme.text,
                                    ),
                                    ReaderSelectableText(
                                      text: _displayContent,
                                      style: _readerTextStyle(theme.text),
                                      textAlign: _readerTextAlign,
                                      onWriteNote: _openNoteEditor,
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
                            Positioned.fill(child: _buildClickZones()),
                          ],
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
                '?? ${_settings.autoReadIntervalSec.toStringAsFixed(1)}s ? ??',
                style: TextStyle(fontSize: 11, color: theme.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
