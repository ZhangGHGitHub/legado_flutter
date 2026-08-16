import '../../application/settings/cache_management_port.dart';
import '../../services/cache_service.dart';

final class CacheManagementPortAdapter implements CacheManagementPort {
  const CacheManagementPortAdapter(this._service);

  final CacheService _service;

  @override
  Future<CacheStatsView> loadStats() async {
    final value = await _service.loadStats();
    return CacheStatsView(
      bookCacheBytes: value.bookCacheBytes,
      dbBytes: value.dbBytes,
      backupsBytes: value.backupsBytes,
    );
  }

  @override
  Future<void> clearBookCache() => _service.clearBookCache();

  @override
  Future<void> clearEngineCache() => _service.clearEngineCache();

  @override
  Future<void> clearBackups() => _service.clearBackups();

  @override
  Future<void> clearAll() => _service.clearAll();
}
