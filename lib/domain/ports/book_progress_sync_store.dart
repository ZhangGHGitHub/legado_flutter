/// Persistence boundary for the last successful book-progress sync time.
abstract interface class BookProgressSyncStore {
  Future<int?> read(String key);

  Future<void> write(String key, int value);
}
