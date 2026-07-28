import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ports/http_tts_cache_port.dart';
import 'http_tts_cache_service.dart';
import 'http_tts_service.dart';

/// TTS 朗读服务（UI-2 / UI-22）。
///
/// 系统引擎经 [FlutterTts] 发音（Android / iOS / macOS）；
/// Windows / Linux 桌面仍支持 HTTP 音频；系统 TTS 依赖平台插件。
enum TtsPlaybackState { idle, playing, paused }

enum TtsCapability { stub, platform, http }

/// 原版 `contentSelectSpeakMod`：0 朗读选区，1 从选区位置开始连续朗读。
enum TtsSelectionSpeakMode { selection, continuous }

typedef HttpTtsAudioSink = Future<void> Function(Uint8List audio);

/// 对齐 Jingshiro [AudioPlay.PlayMode]
enum TtsPlayMode {
  listEndStop('列表播放'),
  singleLoop('单曲循环'),
  random('随机播放'),
  listLoop('列表循环');

  const TtsPlayMode(this.label);
  final String label;

  TtsPlayMode next() {
    const order = TtsPlayMode.values;
    return order[(index + 1) % order.length];
  }
}

class TtsEngineOption {
  final String id;
  final String label;
  const TtsEngineOption(this.id, this.label);
}

class TtsService extends ChangeNotifier {
  TtsService._() : this();
  static final TtsService instance = TtsService._();

  /// 依赖可注入，便于验证 HTTP TTS 的请求和缓存语义；默认构造仍使用
  /// 应用实际的 HTTP 客户端和临时目录缓存。
  TtsService({
    FlutterTts? flutterTts,
    HttpTtsClient? httpClient,
    HttpTtsCachePort? httpCache,
    HttpTtsAudioSink? httpAudioSink,
  }) : _flutterTts = flutterTts ?? _createEngine(),
       _httpClient = httpClient ?? HttpTtsClient(),
       _httpCache = httpCache ?? HttpTtsCacheService(),
       _httpAudioSink = httpAudioSink;

  static const _platformInitTimeout = Duration(seconds: 3);

  static const _selectionSpeakModeKey = 'contentSelectSpeakMod';

  static const List<TtsEngineOption> engines = [
    TtsEngineOption('system', '系统 TTS'),
    TtsEngineOption('http', 'HTTP TTS'),
  ];

  /// Windows / Linux 不创建引擎，避免依赖未注册的 Windows 插件。
  static FlutterTts? _createEngine() {
    if (kIsWeb) return null;
    if (Platform.isWindows || Platform.isLinux) return null;
    return FlutterTts();
  }

  final FlutterTts? _flutterTts;
  final HttpTtsClient _httpClient;
  final HttpTtsCachePort _httpCache;
  final HttpTtsAudioSink? _httpAudioSink;
  AudioPlayer? _httpPlayer;
  HttpTtsConfig? _httpConfig;
  bool _engineReady = false;
  bool _platformAvailable = false;

  TtsPlaybackState _state = TtsPlaybackState.idle;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  String _engineId = 'system';
  bool _backgroundPlay = false;
  int? _timerMinutes;
  DateTime? _timerDeadline;
  Timer? _stopTimer;
  Timer? _timerTick;
  TtsPlayMode _playMode = TtsPlayMode.listEndStop;
  TtsSelectionSpeakMode _selectionSpeakMode = TtsSelectionSpeakMode.selection;
  bool _selectionSpeakModeLoaded = false;

  /// 当当前绑定文本全部朗读完成时触发（含 stub）。
  VoidCallback? onPlaybackCompleted;
  final Set<VoidCallback> _playbackCompletionListeners = <VoidCallback>{};

  List<String> _sentences = const [];
  List<int> _sentenceOffsets = const [];
  int _sentenceIndex = 0;

  TtsPlaybackState get state => _state;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get engineId => _engineId;
  bool get backgroundPlay => _backgroundPlay;
  int? get timerMinutes => _timerMinutes;
  TtsPlayMode get playMode => _playMode;
  TtsSelectionSpeakMode get selectionSpeakMode => _selectionSpeakMode;
  bool get readsFromSelection =>
      _selectionSpeakMode == TtsSelectionSpeakMode.continuous;

  /// 定时关闭剩余分钟（向上取整）；未设置返回 null。
  int? get timerRemainingMinutes {
    final deadline = _timerDeadline;
    if (deadline == null) return null;
    final left = deadline.difference(DateTime.now()).inSeconds;
    if (left <= 0) return 0;
    return (left + 59) ~/ 60;
  }

  TtsCapability get capability =>
      _engineId == 'http' && _httpConfig?.isConfigured == true
      ? TtsCapability.http
      : _engineId == 'system' && _platformAvailable
      ? TtsCapability.platform
      : TtsCapability.stub;
  bool get isActive =>
      _state == TtsPlaybackState.playing || _state == TtsPlaybackState.paused;
  int get sentenceIndex => _sentenceIndex;
  int get sentenceCount => _sentences.length;

  /// 当前句在传入 [bindText] 文本中的起始字符偏移。
  int get currentTextOffset => _sentences.isEmpty
      ? 0
      : _sentenceOffsets[_sentenceIndex.clamp(0, _sentenceOffsets.length - 1)];
  String get currentSentence => _sentences.isEmpty
      ? ''
      : _sentences[_sentenceIndex.clamp(0, _sentences.length - 1)];

  String get engineLabel {
    for (final e in engines) {
      if (e.id == _engineId) return e.label;
    }
    return _engineId;
  }

  bool get httpTtsConfigured => _httpConfig?.isConfigured == true;
  String get httpTtsUrl => _httpConfig?.url ?? '';

  void configureHttpTts(HttpTtsConfig? config) {
    _httpConfig = config;
    notifyListeners();
  }

  Future<void> clearHttpTtsCache() => _httpCache.clear();

  /// 加载原版 `contentSelectSpeakMod`。缺失时保持默认的选区朗读模式。
  Future<void> loadSelectionSpeakMode() async {
    if (_selectionSpeakModeLoaded) return;
    _selectionSpeakModeLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_selectionSpeakModeKey) ?? 0;
      _selectionSpeakMode = value == 1
          ? TtsSelectionSpeakMode.continuous
          : TtsSelectionSpeakMode.selection;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS selection mode load failed: $e');
    }
  }

  void setSelectionSpeakMode(TtsSelectionSpeakMode mode) {
    if (_selectionSpeakMode == mode) return;
    _selectionSpeakMode = mode;
    notifyListeners();
    unawaited(_persistSelectionSpeakMode(mode));
  }

  Future<void> _persistSelectionSpeakMode(TtsSelectionSpeakMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _selectionSpeakModeKey,
        mode == TtsSelectionSpeakMode.continuous ? 1 : 0,
      );
    } catch (e) {
      // Pure Dart tests and early process startup may not have ServicesBinding.
      debugPrint('TTS selection mode save skipped: $e');
    }
  }

  void toggleSelectionSpeakMode() {
    setSelectionSpeakMode(
      _selectionSpeakMode == TtsSelectionSpeakMode.selection
          ? TtsSelectionSpeakMode.continuous
          : TtsSelectionSpeakMode.selection,
    );
  }

  /// 页面型调用方可订阅“当前绑定文本完成”的事件，而不覆盖旧式单回调。
  void addPlaybackCompletedListener(VoidCallback listener) {
    _playbackCompletionListeners.add(listener);
  }

  void removePlaybackCompletedListener(VoidCallback listener) {
    _playbackCompletionListeners.remove(listener);
  }

  Future<void> ensureInitialized() async {
    if (_engineReady) return;
    _engineReady = true;
    final tts = _flutterTts;
    if (tts == null) {
      debugPrint('TTS: stub engine (no platform plugin on this desktop OS)');
      _platformAvailable = false;
      notifyListeners();
      return;
    }
    try {
      tts.setStartHandler(() {
        _state = TtsPlaybackState.playing;
        notifyListeners();
      });
      tts.setCompletionHandler(() {
        _onUtteranceDone();
      });
      tts.setCancelHandler(() {
        if (_state != TtsPlaybackState.idle) {
          _state = TtsPlaybackState.idle;
          notifyListeners();
        }
      });
      tts.setPauseHandler(() {
        _state = TtsPlaybackState.paused;
        notifyListeners();
      });
      tts.setContinueHandler(() {
        _state = TtsPlaybackState.playing;
        notifyListeners();
      });
      tts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _state = TtsPlaybackState.idle;
        notifyListeners();
      });
      if (Platform.isAndroid) {
        final status = await tts.getInitializationStatus.timeout(
          _platformInitTimeout,
        );
        if (status != 1) {
          throw StateError('Android TTS initialization failed: $status');
        }
      }
      // Some Android images expose no TTS engine and leave plugin method
      // calls pending forever. Keep startup and the reader action responsive.
      await _applyVoiceParams().timeout(_platformInitTimeout);
      _platformAvailable = true;
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _platformAvailable = false;
    }
    notifyListeners();
  }

  Future<void> _applyVoiceParams() async {
    final tts = _flutterTts;
    if (tts == null) return;
    // flutter_tts：多数平台 rate ∈ [0,1]，1.0 为正常语速；用 0.5 映射本服务 1.0。
    final rate = (_speechRate * 0.5).clamp(0.0, 1.0);
    await tts.setSpeechRate(rate);
    await tts.setPitch(_pitch.clamp(0.5, 2.0));
  }

  void setSpeechRate(double v) {
    _speechRate = v.clamp(0.5, 3.0);
    unawaited(_applyVoiceParams());
    notifyListeners();
  }

  void setPitch(double v) {
    _pitch = v.clamp(0.5, 2.0);
    unawaited(_applyVoiceParams());
    notifyListeners();
  }

  void setEngineId(String id) {
    if (_engineId == id) return;
    if (isActive) unawaited(stop());
    _engineId = id;
    // HTTP TTS has its own audio pipeline and must not inherit a failed
    // platform-engine initialization from the previous system mode.
    _engineReady = false;
    _platformAvailable = false;
    notifyListeners();
  }

  void setBackgroundPlay(bool v) {
    _backgroundPlay = v;
    notifyListeners();
  }

  void setPlayMode(TtsPlayMode mode) {
    _playMode = mode;
    notifyListeners();
  }

  void cyclePlayMode() {
    _playMode = _playMode.next();
    notifyListeners();
  }

  void setTimerMinutes(int? minutes) {
    _timerMinutes = minutes;
    _stopTimer?.cancel();
    _stopTimer = null;
    _timerTick?.cancel();
    _timerTick = null;
    _timerDeadline = null;
    if (minutes != null && minutes > 0) {
      _timerDeadline = DateTime.now().add(Duration(minutes: minutes));
      _stopTimer = Timer(Duration(minutes: minutes), () {
        _timerDeadline = null;
        _timerTick?.cancel();
        _timerTick = null;
        unawaited(stop());
        notifyListeners();
      });
      // 便于 UI 显示剩余分钟（对齐 Jingshiro AUDIO_DS）。
      _timerTick = Timer.periodic(const Duration(seconds: 15), (_) {
        notifyListeners();
      });
    }
    notifyListeners();
  }

  static List<String> splitSentences(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    final parts = trimmed.split(RegExp(r'(?<=[。！？；….!?;\n])'));
    final out = <String>[];
    for (final p in parts) {
      final s = p.trim();
      if (s.isNotEmpty) out.add(s);
    }
    return out.isEmpty ? [trimmed] : out;
  }

  void bindText(String text) {
    final trimmed = text.trim();
    _sentences = splitSentences(text);
    final baseOffset = trimmed.isEmpty ? 0 : text.indexOf(trimmed);
    final offsets = <int>[];
    var searchFrom = 0;
    for (final sentence in _sentences) {
      final found = trimmed.indexOf(sentence, searchFrom);
      final offset = found < 0 ? searchFrom : found;
      offsets.add((baseOffset < 0 ? 0 : baseOffset) + offset);
      searchFrom = offset + sentence.length;
    }
    _sentenceOffsets = offsets;
    _sentenceIndex = 0;
    notifyListeners();
  }

  Future<bool> speak(String text) async {
    if (_engineId == 'system') {
      await ensureInitialized();
    }
    bindText(text);
    if (_sentences.isEmpty) return false;
    return _speakFromCurrent();
  }

  /// 选中文本菜单的默认朗读语义（原版 contentSelectSpeakMod=0）。
  Future<bool> speakSelection(String text) => speak(text.trim());

  /// 从正文的章内字符位置开始朗读（原版 contentSelectSpeakMod=1）。
  ///
  /// 位置只用于截取起点，不改变正文内容、净化顺序或分页输入。
  Future<bool> speakFromOffset(String text, int startOffset) {
    if (text.isEmpty) return Future.value(false);
    final offset = startOffset.clamp(0, text.length);
    return speak(text.substring(offset));
  }

  Future<bool> _speakFromCurrent() async {
    if (_engineId == 'http') {
      final config = _httpConfig;
      if (config == null || !config.isConfigured) {
        _state = TtsPlaybackState.idle;
        notifyListeners();
        return false;
      }
      try {
        final request = config.resolve(currentSentence, _speechRate);
        final audio = await _httpCache.getOrFetch(
          configurationKey: config.cacheIdentity,
          text: currentSentence,
          speed: _speechRate,
          fetch: () => _httpClient.fetchAudio(request),
        );
        final audioSink = _httpAudioSink;
        if (audioSink != null) {
          await audioSink(audio);
        } else {
          final player = _ensureHttpPlayer();
          await player.stop();
          await player.setSourceBytes(audio);
          await player.resume();
        }
        _state = TtsPlaybackState.playing;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('HTTP TTS 播放失败: $e');
        _state = TtsPlaybackState.idle;
        notifyListeners();
        return false;
      }
    }
    final tts = _flutterTts;
    if (!_platformAvailable || tts == null) {
      debugPrint('TTS platform unavailable (stub)');
      _state = TtsPlaybackState.playing;
      notifyListeners();
      return false;
    }
    final sentence = currentSentence;
    if (sentence.isEmpty) return false;
    try {
      await _applyVoiceParams();
      _state = TtsPlaybackState.playing;
      notifyListeners();
      await tts.speak(sentence);
      return true;
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      _state = TtsPlaybackState.idle;
      notifyListeners();
      return false;
    }
  }

  void _onUtteranceDone() {
    if (_state != TtsPlaybackState.playing) return;
    if (_sentenceIndex < _sentences.length - 1) {
      _sentenceIndex++;
      notifyListeners();
      unawaited(_speakFromCurrent());
      return;
    }
    _state = TtsPlaybackState.idle;
    notifyListeners();
    onPlaybackCompleted?.call();
    for (final listener in List<VoidCallback>.of(
      _playbackCompletionListeners,
    )) {
      listener();
    }
  }

  /// 跳转到指定句并可选继续播放（快进/后退）。
  Future<void> seekSentence(int index, {bool resumeIfActive = true}) async {
    if (_sentences.isEmpty) return;
    final wasActive = isActive;
    _sentenceIndex = index.clamp(0, _sentences.length - 1);
    notifyListeners();
    if (resumeIfActive && wasActive) {
      await stop();
      await _speakFromCurrent();
    }
  }

  Future<void> pause() async {
    if (_state != TtsPlaybackState.playing) return;
    final tts = _flutterTts;
    if (_engineId == 'http') {
      try {
        await _httpPlayer?.pause();
      } catch (_) {}
      _state = TtsPlaybackState.paused;
      notifyListeners();
      return;
    }
    if (_engineId == 'system' && _platformAvailable && tts != null) {
      try {
        await tts.pause();
      } catch (_) {}
    }
    _state = TtsPlaybackState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_state != TtsPlaybackState.paused) return;
    if (_engineId == 'http') {
      try {
        await _httpPlayer?.resume();
        _state = TtsPlaybackState.playing;
        notifyListeners();
      } catch (_) {
        await _speakFromCurrent();
      }
      return;
    }
    if (_engineId == 'system' && _platformAvailable && _flutterTts != null) {
      // 部分平台无真正 resume，重说当前句。
      await _speakFromCurrent();
      return;
    }
    _state = TtsPlaybackState.playing;
    notifyListeners();
  }

  Future<void> stop() async {
    final tts = _flutterTts;
    if (_engineId == 'http') {
      try {
        await _httpPlayer?.stop();
      } catch (_) {}
    }
    if (_engineId == 'system' && _platformAvailable && tts != null) {
      try {
        await tts.stop();
      } catch (_) {}
    }
    if (_state != TtsPlaybackState.idle) {
      _state = TtsPlaybackState.idle;
      notifyListeners();
    }
  }

  Future<void> togglePlay(String text) async {
    switch (_state) {
      case TtsPlaybackState.idle:
        await speak(text);
      case TtsPlaybackState.playing:
        await pause();
      case TtsPlaybackState.paused:
        await resume();
    }
  }

  Future<void> previousSentence() async {
    if (_sentences.isEmpty) return;
    final wasActive = isActive;
    if (_sentenceIndex > 0) {
      _sentenceIndex--;
    }
    notifyListeners();
    if (wasActive) {
      await stop();
      await _speakFromCurrent();
    }
  }

  Future<void> nextSentence() async {
    if (_sentences.isEmpty) return;
    final wasActive = isActive;
    if (_sentenceIndex < _sentences.length - 1) {
      _sentenceIndex++;
    }
    notifyListeners();
    if (wasActive) {
      await stop();
      await _speakFromCurrent();
    }
  }

  AudioPlayer _ensureHttpPlayer() {
    final existing = _httpPlayer;
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) => _onUtteranceDone());
    _httpPlayer = player;
    return player;
  }
}
