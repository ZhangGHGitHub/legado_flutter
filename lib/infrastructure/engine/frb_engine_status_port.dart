import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/engine_status_port.dart';

/// FRB adapter for the engine status used by application pages.
class FrbEngineStatusPort implements EngineStatusPort {
  const FrbEngineStatusPort();

  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  String get engineVersion =>
      isAvailable ? LegadoEngineBridge.engineVersion() : '';
}
