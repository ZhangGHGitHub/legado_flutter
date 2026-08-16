import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../application/crash/crash_log_service.dart';
import '../../domain/crash/crash_report.dart';

class GlobalCrashHandler {
  GlobalCrashHandler({required CrashLogService crashLog})
    : _crashLog = crashLog;

  final CrashLogService _crashLog;

  FlutterExceptionHandler? _previousFlutterHandler;
  ErrorCallback? _previousPlatformHandler;
  bool _installed = false;

  void install() {
    if (_installed) return;
    _installed = true;
    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    FlutterError.onError = handleFlutterError;
    PlatformDispatcher.instance.onError = handlePlatformError;
  }

  void restore() {
    if (!_installed) return;
    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
    _previousFlutterHandler = null;
    _previousPlatformHandler = null;
    _installed = false;
  }

  void handleFlutterError(FlutterErrorDetails details) {
    final previous = _previousFlutterHandler;
    if (previous != null && previous != handleFlutterError) {
      previous(details);
    } else {
      FlutterError.presentError(details);
    }
    unawaited(
      _crashLog.record(
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.current,
        origin: CrashOrigin.flutterFramework,
      ),
    );
  }

  bool handlePlatformError(Object error, StackTrace stackTrace) {
    unawaited(
      _crashLog.record(
        error: error,
        stackTrace: stackTrace,
        origin: CrashOrigin.platformDispatcher,
      ),
    );
    return _previousPlatformHandler?.call(error, stackTrace) ?? false;
  }

  void handleZoneError(Object error, StackTrace stackTrace) {
    unawaited(
      _crashLog.record(
        error: error,
        stackTrace: stackTrace,
        origin: CrashOrigin.unhandledZone,
      ),
    );
  }
}
