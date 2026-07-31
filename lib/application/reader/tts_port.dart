import 'package:flutter/foundation.dart';

enum TtsPlaybackStatePort { idle, playing, paused }

enum TtsCapabilityPort { stub, platform, http }

enum TtsSelectionSpeakModePort { selection, continuous }

enum TtsPlayModePort {
  listEndStop('列表播放'),
  singleLoop('单曲循环'),
  random('随机播放'),
  listLoop('列表循环');

  const TtsPlayModePort(this.label);
  final String label;
}

final class TtsEngineOptionPort {
  const TtsEngineOptionPort(this.id, this.label);

  final String id;
  final String label;
}

abstract interface class TtsPort extends Listenable {
  List<TtsEngineOptionPort> get engines;
  TtsPlaybackStatePort get state;
  TtsCapabilityPort get capability;
  TtsPlayModePort get playMode;
  String get engineId;
  String get engineLabel;
  double get speechRate;
  double get pitch;
  int? get timerMinutes;
  int? get timerRemainingMinutes;
  int get sentenceIndex;
  int get sentenceCount;
  String get currentSentence;
  int get currentTextOffset;
  TtsSelectionSpeakModePort get selectionSpeakMode;
  bool get httpTtsConfigured;
  String get httpTtsUrl;

  VoidCallback? get onPlaybackCompleted;
  set onPlaybackCompleted(VoidCallback? listener);

  Future<void> ensureInitialized();
  void bindText(String text);
  Future<void> togglePlay(String text);
  Future<void> speak(String text);
  Future<bool> speakSelection(String text);
  Future<bool> speakFromOffset(String text, int startOffset);
  Future<void> loadSelectionSpeakMode();
  void setSelectionSpeakMode(TtsSelectionSpeakModePort mode);
  void addPlaybackCompletedListener(VoidCallback listener);
  void removePlaybackCompletedListener(VoidCallback listener);
  Future<void> stop();
  Future<void> seekSentence(int index);
  Future<void> previousSentence();
  Future<void> nextSentence();
  void setEngineId(String id);
  void configureHttpTts(String url);
  void setTimerMinutes(int? minutes);
  void setSpeechRate(double value);
  void setPitch(double value);
  bool get backgroundPlay;
  void setBackgroundPlay(bool value);
  void cyclePlayMode();
}
