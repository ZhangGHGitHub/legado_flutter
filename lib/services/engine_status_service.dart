import 'package:flutter/foundation.dart';

import '../domain/ports/engine_status_port.dart';

/// Engine status needed by application-facing pages.
abstract final class EngineStatusService {
  static EngineStatusPort? _port;

  static bool get isAvailable => _port?.isAvailable ?? false;

  static String get engineVersion => _port?.engineVersion ?? '';

  static void configurePort(EngineStatusPort port) {
    _port = port;
  }

  @visibleForTesting
  static void resetPort() {
    _port = null;
  }
}
