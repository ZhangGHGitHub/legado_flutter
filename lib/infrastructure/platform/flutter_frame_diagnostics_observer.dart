import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../../application/diagnostics/app_diagnostics_monitor.dart';

class FlutterFrameDiagnosticsObserver {
  FlutterFrameDiagnosticsObserver(this._monitor);

  final AppDiagnosticsMonitor _monitor;
  Timer? _freezeTimer;
  DateTime? _lastFreezeTick;
  bool _started = false;
  bool _timingsStarted = false;

  void start() {
    if (_started) return;
    _started = true;
    if (!_monitor.isEnabled) return;

    final config = _monitor.config;
    if (config.recordFrames) {
      SchedulerBinding.instance.addTimingsCallback(_handleTimings);
      _timingsStarted = true;
    }
    if (config.recordFreeze) {
      _lastFreezeTick = DateTime.now();
      _freezeTimer = Timer.periodic(config.freezeProbeInterval, (_) {
        final now = DateTime.now();
        final previous = _lastFreezeTick ?? now;
        _lastFreezeTick = now;
        unawaited(
          _monitor.recordFreezeSample(
            elapsed: now.difference(previous),
            expectedInterval: config.freezeProbeInterval,
          ),
        );
      });
    }
  }

  void stop() {
    if (_timingsStarted) {
      SchedulerBinding.instance.removeTimingsCallback(_handleTimings);
      _timingsStarted = false;
    }
    _freezeTimer?.cancel();
    _freezeTimer = null;
    _lastFreezeTick = null;
    _started = false;
  }

  void _handleTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      unawaited(
        _monitor.recordFrameTiming(
          buildDuration: timing.buildDuration,
          rasterDuration: timing.rasterDuration,
          totalSpan: timing.totalSpan,
        ),
      );
    }
  }
}
