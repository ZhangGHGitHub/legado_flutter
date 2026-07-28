/// Persistence boundary for the bookshelf group JSON document.
abstract interface class BookGroupPrefsPort {
  Future<String?> read(String key);

  Future<bool> write(String key, String value);
}
