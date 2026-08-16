final class CacheStatsView {
  const CacheStatsView({
    required this.bookCacheBytes,
    required this.dbBytes,
    required this.backupsBytes,
  });

  final int bookCacheBytes;
  final int dbBytes;
  final int backupsBytes;

  int get totalBytes => bookCacheBytes + dbBytes + backupsBytes;

  String get totalLabel => _formatBytes(totalBytes);
  String get bookCacheLabel => _formatBytes(bookCacheBytes);
  String get dbLabel => _formatBytes(dbBytes);
  String get backupsLabel => _formatBytes(backupsBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

abstract interface class CacheManagementPort {
  Future<CacheStatsView> loadStats();

  Future<void> clearBookCache();

  Future<void> clearEngineCache();

  Future<void> clearBackups();

  Future<void> clearAll();
}
