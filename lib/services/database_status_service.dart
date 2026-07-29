import 'package:flutter/foundation.dart';

import '../domain/ports/database_status_port.dart';

/// Database readiness needed by application-facing pages.
abstract final class DatabaseStatusService {
  static DatabaseStatusPort? _port;

  static bool get isReady => _port?.isReady ?? false;

  static void configurePort(DatabaseStatusPort port) {
    _port = port;
  }

  @visibleForTesting
  static void resetPort() {
    _port = null;
  }
}
