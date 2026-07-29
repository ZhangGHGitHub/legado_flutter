import 'dart:async';

import '../startup/startup_task_runner.dart';

enum AppDiagnosticEventKind {
  slowFrame,
  appFreeze,
  dispatcherTimeout,
  startupTaskTimeout,
  startupTaskFailure,
}

class AppDiagnosticsConfig {
  const AppDiagnosticsConfig({
    this.enabled = false,
    this.recordFrames = true,
    this.recordFreeze = true,
    this.recordDispatchers = true,
    this.recordStartupTasks = true,
    this.frameBudget = const Duration(milliseconds: 16),
    this.freezeProbeInterval = const Duration(seconds: 3),
    this.freezeTolerance = const Duration(milliseconds: 300),
    this.dispatcherTimeout = const Duration(seconds: 5),
  });

  const AppDiagnosticsConfig.disabled() : this();

  final bool enabled;
  final bool recordFrames;
  final bool recordFreeze;
  final bool recordDispatchers;
  final bool recordStartupTasks;
  final Duration frameBudget;
  final Duration freezeProbeInterval;
  final Duration freezeTolerance;
  final Duration dispatcherTimeout;
}

class AppDiagnosticEvent {
  const AppDiagnosticEvent({
    required this.kind,
    required this.source,
    required this.message,
    required this.occurredAt,
    this.duration,
    this.threshold,
    this.error,
    this.stackTrace,
  });

  final AppDiagnosticEventKind kind;
  final String source;
  final String message;
  final DateTime occurredAt;
  final Duration? duration;
  final Duration? threshold;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isCrash => false;
  String get level => 'W';

  String toLogLine() {
    final parts = <String>['[Diagnostics][${kind.name}][$source]', message];
    final elapsed = duration;
    if (elapsed != null) parts.add('duration=${elapsed.inMilliseconds}ms');
    final limit = threshold;
    if (limit != null) parts.add('threshold=${limit.inMilliseconds}ms');
    final e = error;
    if (e != null) parts.add('error=$e');
    return parts.join(' ');
  }
}

typedef AppDiagnosticSink = FutureOr<void> Function(AppDiagnosticEvent event);

class AppDiagnosticsMonitor {
  AppDiagnosticsMonitor({
    required this.config,
    required AppDiagnosticSink sink,
    DateTime Function()? clock,
  }) : _sink = sink,
       _clock = clock ?? DateTime.now;

  static const _maxEvents = 100;

  final AppDiagnosticsConfig config;
  final AppDiagnosticSink _sink;
  final DateTime Function() _clock;
  final List<AppDiagnosticEvent> _events = [];

  bool get isEnabled => config.enabled;
  List<AppDiagnosticEvent> get events => List.unmodifiable(_events);

  Future<AppDiagnosticEvent?> recordFrameTiming({
    required Duration buildDuration,
    required Duration rasterDuration,
    required Duration totalSpan,
    String source = 'flutter.frame',
  }) {
    if (!config.enabled || !config.recordFrames) {
      return Future<AppDiagnosticEvent?>.value();
    }
    if (totalSpan <= config.frameBudget) {
      return Future<AppDiagnosticEvent?>.value();
    }
    return _emit(
      AppDiagnosticEvent(
        kind: AppDiagnosticEventKind.slowFrame,
        source: source,
        occurredAt: _clock(),
        duration: totalSpan,
        threshold: config.frameBudget,
        message:
            '检测到慢帧 build=${buildDuration.inMilliseconds}ms '
            'raster=${rasterDuration.inMilliseconds}ms',
      ),
    );
  }

  Future<AppDiagnosticEvent?> recordFreezeSample({
    required Duration elapsed,
    required Duration expectedInterval,
    String source = 'main_isolate.timer',
  }) {
    if (!config.enabled || !config.recordFreeze) {
      return Future<AppDiagnosticEvent?>.value();
    }
    final extra = elapsed - expectedInterval;
    if (extra <= config.freezeTolerance) {
      return Future<AppDiagnosticEvent?>.value();
    }
    return _emit(
      AppDiagnosticEvent(
        kind: AppDiagnosticEventKind.appFreeze,
        source: source,
        occurredAt: _clock(),
        duration: extra,
        threshold: config.freezeTolerance,
        message: '检测到应用主 isolate 可能被冻结',
      ),
    );
  }

  Future<AppDiagnosticEvent?> recordDispatcherTimeout({
    required String dispatcher,
    required Duration waited,
  }) {
    if (!config.enabled || !config.recordDispatchers) {
      return Future<AppDiagnosticEvent?>.value();
    }
    if (waited < config.dispatcherTimeout) {
      return Future<AppDiagnosticEvent?>.value();
    }
    return _emit(
      AppDiagnosticEvent(
        kind: AppDiagnosticEventKind.dispatcherTimeout,
        source: dispatcher,
        occurredAt: _clock(),
        duration: waited,
        threshold: config.dispatcherTimeout,
        message: '调度器响应超过阈值',
      ),
    );
  }

  Future<AppDiagnosticEvent?> recordStartupTask(StartupTaskReport report) {
    if (!config.enabled || !config.recordStartupTasks) {
      return Future<AppDiagnosticEvent?>.value();
    }
    if (report.status != StartupTaskStatus.failed) {
      return Future<AppDiagnosticEvent?>.value();
    }
    final error = report.error;
    final isTimeout = error is TimeoutException;
    return _emit(
      AppDiagnosticEvent(
        kind: isTimeout
            ? AppDiagnosticEventKind.startupTaskTimeout
            : AppDiagnosticEventKind.startupTaskFailure,
        source: report.id,
        occurredAt: _clock(),
        duration: report.elapsed,
        threshold: isTimeout ? StartupTaskRunner.defaultTimeout : null,
        error: error,
        stackTrace: report.stackTrace,
        message: isTimeout ? '启动后台任务超时' : '启动后台任务失败',
      ),
    );
  }

  Future<AppDiagnosticEvent?> _emit(AppDiagnosticEvent event) async {
    _events.insert(0, event);
    while (_events.length > _maxEvents) {
      _events.removeLast();
    }
    await _sink(event);
    return event;
  }
}
