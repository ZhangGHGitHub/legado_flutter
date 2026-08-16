import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/engine_status_port.dart';
import 'package:legado_flutter/services/engine_status_service.dart';

void main() {
  tearDown(EngineStatusService.resetPort);

  test('exposes status and version through the replaceable port', () {
    EngineStatusService.configurePort(
      const _FakeEngineStatusPort(
        isAvailable: true,
        engineVersion: 'test-engine',
      ),
    );

    expect(EngineStatusService.isAvailable, isTrue);
    expect(EngineStatusService.engineVersion, 'test-engine');
  });

  test('preserves unavailable status without reading a bridge version', () {
    EngineStatusService.configurePort(
      const _FakeEngineStatusPort(isAvailable: false, engineVersion: ''),
    );

    expect(EngineStatusService.isAvailable, isFalse);
    expect(EngineStatusService.engineVersion, isEmpty);
  });
}

class _FakeEngineStatusPort implements EngineStatusPort {
  const _FakeEngineStatusPort({
    required this.isAvailable,
    required this.engineVersion,
  });

  @override
  final bool isAvailable;

  @override
  final String engineVersion;
}
