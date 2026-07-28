import '../application/database/legacy_room_import_service.dart';
import '../infrastructure/database/frb_legacy_room_import_port.dart';

/// Application-facing factory for the Room import use case.
abstract final class LegacyRoomImportServices {
  static LegacyRoomImportService create() {
    return LegacyRoomImportService(FrbLegacyRoomImportPort());
  }
}
