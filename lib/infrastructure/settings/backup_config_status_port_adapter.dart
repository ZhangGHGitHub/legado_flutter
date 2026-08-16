import '../../application/settings/backup_config_status_port.dart';
import '../../services/database_status_service.dart';
import '../../services/engine_status_service.dart';

final class BackupConfigStatusPortAdapter implements BackupConfigStatusPort {
  const BackupConfigStatusPortAdapter();

  @override
  bool get engineReady =>
      EngineStatusService.isAvailable && DatabaseStatusService.isReady;
}
