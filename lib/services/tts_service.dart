import 'package:flutter/foundation.dart';

/// TTS 朗读服务骨架（UI-2）。
///
/// 未接入 `flutter_tts` / 平台引擎前：配置与状态可变更，
/// [speak]/[pause]/[resume]/[stop] 明确报告 [TtsCapability.stub]。
enum TtsPlaybackState { idle, playing, paused }

enum TtsCapability { stub, platform }

class TtsEngineOption {
  final String id;
  final String label;
  const TtsEngineOption(this.id, this.label);
}

class TtsService extends ChangeNotifier {
  TtsService._();
  static final TtsService instance = TtsService._();

  static const List<TtsEngineOption> engines = [
    TtsEngineOption('system', '系统 TTS（待接插件）'),
    TtsEngineOption('http', 'HTTP TTS（待实现）'),
  ];

  TtsPlaybackState _state = TtsPlaybackState.idle;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  String _engineId = 'system';
  bool _backgroundPlay = false;
  int? _timerMinutes;

  TtsPlaybackState get state => _state;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get engineId => _engineId;
  bool get backgroundPlay => _backgroundPlay;
  int? get timerMinutes => _timerMinutes;
  TtsCapability get capability => TtsCapability.stub;
  bool get isActive =>
      _state == TtsPlaybackState.playing || _state == TtsPlaybackState.paused;

  String get engineLabel {
    for (final e in engines) {
      if (e.id == _engineId) return e.label;
    }
    return _engineId;
  }

  void setSpeechRate(double v) {
    _speechRate = v.clamp(0.5, 2.0);
    notifyListeners();
  }

  void setPitch(double v) {
    _pitch = v.clamp(0.5, 2.0);
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
    notifyListeners();
  }

  /// 返回 false 表示当前仅为 stub，UI 应提示未接平台引擎。
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;
    debugPrint(
      'TTS stub speak: engine=$_engineId rate=$_speechRate '
      'pitch=$_pitch chars=${text.length}',
    );
    _state = TtsPlaybackState.playing;
    notifyListeners();
    return false;
  }

  Future<void> pause() async {
    if (_state == TtsPlaybackState.playing) {
      _state = TtsPlaybackState.paused;
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (_state == TtsPlaybackState.paused) {
      _state = TtsPlaybackState.playing;
      notifyListeners();
    }
  }

  Future<void> stop() async {
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
}
