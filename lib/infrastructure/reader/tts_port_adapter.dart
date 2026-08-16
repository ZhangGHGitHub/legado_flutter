import 'package:flutter/foundation.dart';

import '../../application/reader/tts_port.dart';
import '../../services/http_tts_service.dart';
import '../../services/tts_service.dart';

final class TtsPortAdapter implements TtsPort {
  TtsPortAdapter(this._service);

  final TtsService _service;

  @override
  List<TtsEngineOptionPort> get engines => [
    for (final option in TtsService.engines)
      TtsEngineOptionPort(option.id, option.label),
  ];

  @override
  TtsPlaybackStatePort get state => switch (_service.state) {
    TtsPlaybackState.idle => TtsPlaybackStatePort.idle,
    TtsPlaybackState.playing => TtsPlaybackStatePort.playing,
    TtsPlaybackState.paused => TtsPlaybackStatePort.paused,
  };

  @override
  TtsCapabilityPort get capability => switch (_service.capability) {
    TtsCapability.stub => TtsCapabilityPort.stub,
    TtsCapability.platform => TtsCapabilityPort.platform,
    TtsCapability.http => TtsCapabilityPort.http,
  };

  @override
  TtsPlayModePort get playMode => switch (_service.playMode) {
    TtsPlayMode.listEndStop => TtsPlayModePort.listEndStop,
    TtsPlayMode.singleLoop => TtsPlayModePort.singleLoop,
    TtsPlayMode.random => TtsPlayModePort.random,
    TtsPlayMode.listLoop => TtsPlayModePort.listLoop,
  };

  @override
  String get engineId => _service.engineId;

  @override
  String get engineLabel => _service.engineLabel;

  @override
  double get speechRate => _service.speechRate;

  @override
  double get pitch => _service.pitch;

  @override
  int? get timerMinutes => _service.timerMinutes;

  @override
  int? get timerRemainingMinutes => _service.timerRemainingMinutes;

  @override
  int get sentenceIndex => _service.sentenceIndex;

  @override
  int get sentenceCount => _service.sentenceCount;

  @override
  String get currentSentence => _service.currentSentence;

  @override
  int get currentTextOffset => _service.currentTextOffset;

  @override
  TtsSelectionSpeakModePort get selectionSpeakMode =>
      switch (_service.selectionSpeakMode) {
        TtsSelectionSpeakMode.selection => TtsSelectionSpeakModePort.selection,
        TtsSelectionSpeakMode.continuous =>
          TtsSelectionSpeakModePort.continuous,
      };

  @override
  bool get httpTtsConfigured => _service.httpTtsConfigured;

  @override
  String get httpTtsUrl => _service.httpTtsUrl;

  @override
  VoidCallback? get onPlaybackCompleted => _service.onPlaybackCompleted;

  @override
  set onPlaybackCompleted(VoidCallback? listener) {
    _service.onPlaybackCompleted = listener;
  }

  @override
  void addListener(VoidCallback listener) => _service.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _service.removeListener(listener);

  @override
  Future<void> ensureInitialized() => _service.ensureInitialized();

  @override
  void bindText(String text) => _service.bindText(text);

  @override
  Future<void> togglePlay(String text) => _service.togglePlay(text);

  @override
  Future<void> speak(String text) => _service.speak(text);

  @override
  Future<bool> speakSelection(String text) => _service.speakSelection(text);

  @override
  Future<bool> speakFromOffset(String text, int startOffset) =>
      _service.speakFromOffset(text, startOffset);

  @override
  Future<void> loadSelectionSpeakMode() => _service.loadSelectionSpeakMode();

  @override
  void setSelectionSpeakMode(TtsSelectionSpeakModePort mode) {
    _service.setSelectionSpeakMode(
      mode == TtsSelectionSpeakModePort.continuous
          ? TtsSelectionSpeakMode.continuous
          : TtsSelectionSpeakMode.selection,
    );
  }

  @override
  void addPlaybackCompletedListener(VoidCallback listener) =>
      _service.addPlaybackCompletedListener(listener);

  @override
  void removePlaybackCompletedListener(VoidCallback listener) =>
      _service.removePlaybackCompletedListener(listener);

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> seekSentence(int index) => _service.seekSentence(index);

  @override
  Future<void> previousSentence() => _service.previousSentence();

  @override
  Future<void> nextSentence() => _service.nextSentence();

  @override
  void setEngineId(String id) => _service.setEngineId(id);

  @override
  void configureHttpTts(String url) {
    _service.configureHttpTts(HttpTtsConfig(url: url));
  }

  @override
  void setTimerMinutes(int? minutes) => _service.setTimerMinutes(minutes);

  @override
  void setSpeechRate(double value) => _service.setSpeechRate(value);

  @override
  void setPitch(double value) => _service.setPitch(value);

  @override
  bool get backgroundPlay => _service.backgroundPlay;

  @override
  void setBackgroundPlay(bool value) => _service.setBackgroundPlay(value);

  @override
  void cyclePlayMode() => _service.cyclePlayMode();
}
