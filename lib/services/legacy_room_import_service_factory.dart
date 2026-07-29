import '../application/database/legacy_room_import_service.dart';
import '../domain/ports/legacy_room_import_port.dart';

/// Application-facing factory for the Room import use case.
abstract final class LegacyRoomImportServices {
  static LegacyRoomImportService create(LegacyRoomImportPort port) {
    return LegacyRoomImportService(port);
  }
}
