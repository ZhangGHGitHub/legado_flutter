import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/database_status_port.dart';
import 'package:legado_flutter/domain/ports/engine_status_port.dart';
import 'package:legado_flutter/services/database_status_service.dart';
import 'package:legado_flutter/services/engine_status_service.dart';

void main() {
  tearDown(() {
    DatabaseStatusService.resetPort();
    EngineStatusService.resetPort();
  });

  test('database status port is explicit and reset does not restore it', () {
    DatabaseStatusService.configurePort(const _DatabaseStatusPort(true));
    expect(DatabaseStatusService.isReady, isTrue);

    DatabaseStatusService.resetPort();
    expect(DatabaseStatusService.isReady, isFalse);
  });

  test('engine status port is explicit and reset does not restore it', () {
    EngineStatusService.configurePort(const _EngineStatusPort());
    expect(EngineStatusService.isAvailable, isTrue);
    expect(EngineStatusService.engineVersion, 'test-engine');

    EngineStatusService.resetPort();
    expect(EngineStatusService.isAvailable, isFalse);
    expect(EngineStatusService.engineVersion, isEmpty);
  });
}

class _DatabaseStatusPort implements DatabaseStatusPort {
  const _DatabaseStatusPort(this.isReady);

  @override
  final bool isReady;
}

class _EngineStatusPort implements EngineStatusPort {
  const _EngineStatusPort();

  @override
  bool get isAvailable => true;

  @override
  String get engineVersion => 'test-engine';
}
