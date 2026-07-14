import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS 朗读服务（UI-2）。
///
/// 系统引擎经 [FlutterTts] 发音（Android / iOS / macOS）；
/// Windows / Linux 桌面无原生插件（避免 nuget），走 stub；HTTP TTS 仍为占位。
enum TtsPlaybackState { idle, playing, paused }

enum TtsCapability { stub, platform }

class TtsEngineOption {
  final String id;
  final String label;
  const TtsEngineOption(this.id, this.label);
}

class TtsService extends ChangeNotifier {
  TtsService._() : _flutterTts = _createEngine();
  static final TtsService instance = TtsService._();

  static const List<TtsEngineOption> engines = [
    TtsEngineOption('system', '系统 TTS'),
    TtsEngineOption('http', 'HTTP TTS（待实现）'),
  ];

  /// Windows / Linux 不创建引擎，避免依赖未注册的 Windows 插件。
  static FlutterTts? _createEngine() {
    if (kIsWeb) return null;
    if (Platform.isWindows || Platform.isLinux) return null;
    return FlutterTts();
  }

  final FlutterTts? _flutterTts;
  bool _engineReady = false;
  bool _platformAvailable = false;

  TtsPlaybackState _state = TtsPlaybackState.idle;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  String _engineId = 'system';
  bool _backgroundPlay = false;
  int? _timerMinutes;
  Timer? _stopTimer;

  String _fullText = '';
  List<String> _sentences = const [];
  int _sentenceIndex = 0;

  TtsPlaybackState get state => _state;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get engineId => _engineId;
  bool get backgroundPlay => _backgroundPlay;
  int? get timerMinutes => _timerMinutes;
  TtsCapability get capability =>
      _engineId == 'system' && _platformAvailable
          ? TtsCapability.platform
          : TtsCapability.stub;
  bool get isActive =>
      _state == TtsPlaybackState.playing || _state == TtsPlaybackState.paused;
  int get sentenceIndex => _sentenceIndex;
  int get sentenceCount => _sentences.length;
  String get currentSentence =>
      _sentences.isEmpty ? '' : _sentences[_sentenceIndex.clamp(0, _sentences.length - 1)];

  String get engineLabel {
    for (final e in engines) {
      if (e.id == _engineId) return e.label;
    }
    return _engineId;
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
      await _applyVoiceParams();
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
    _speechRate = v.clamp(0.5, 2.0);
    unawaited(_applyVoiceParams());
    notifyListeners();
  }

  void setPitch(double v) {
    _pitch = v.clamp(0.5, 2.0);
    unawaited(_applyVoiceParams());
    notifyListeners();
  }

  void setEngineId(String id) {
    _engineId = id;
    notifyListeners();
  }

  void setBackgroundPlay(bool v) {
    _backgroundPlay = v;
    notifyListeners();
  }

  void setTimerMinutes(int? minutes) {
    _timerMinutes = minutes;
    _stopTimer?.cancel();
    _stopTimer = null;
    if (minutes != null && minutes > 0) {
      _stopTimer = Timer(Duration(minutes: minutes), () {
        unawaited(stop());
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
    _fullText = text;
    _sentences = splitSentences(text);
    _sentenceIndex = 0;
    notifyListeners();
  }

  Future<bool> speak(String text) async {
    await ensureInitialized();
    bindText(text);
    if (_sentences.isEmpty) return false;
    return _speakFromCurrent();
  }

  Future<bool> _speakFromCurrent() async {
    if (_engineId == 'http') {
      debugPrint('TTS http stub speak chars=${_fullText.length}');
      _state = TtsPlaybackState.playing;
      notifyListeners();
      return false;
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
  }

  Future<void> pause() async {
    if (_state != TtsPlaybackState.playing) return;
    final tts = _flutterTts;
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
}
