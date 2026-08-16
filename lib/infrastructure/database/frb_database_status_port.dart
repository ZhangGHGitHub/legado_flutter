import '../../bridge/legado_db_bridge.dart';
import '../../domain/ports/database_status_port.dart';

/// FRB-backed database readiness adapter.
class FrbDatabaseStatusPort implements DatabaseStatusPort {
  const FrbDatabaseStatusPort();

  @override
  bool get isReady => LegadoDbBridge.isReady;
}
