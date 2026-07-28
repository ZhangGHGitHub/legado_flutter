import 'package:flutter/foundation.dart';

import '../domain/ports/engine_status_port.dart';
import '../infrastructure/engine/frb_engine_status_port.dart';

/// Engine status needed by application-facing pages.
abstract final class EngineStatusService {
  static EngineStatusPort _port = const FrbEngineStatusPort();

  static bool get isAvailable => _port.isAvailable;

  static String get engineVersion => _port.engineVersion;

  @visibleForTesting
  static void configurePort(EngineStatusPort port) {
    _port = port;
  }

  @visibleForTesting
  static void resetPort() {
    _port = const FrbEngineStatusPort();
  }
}
