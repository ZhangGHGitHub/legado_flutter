/// 搜索历史的应用层持久化边界。
abstract interface class SearchHistoryPort {
  Future<List<String>> load();

  Future<void> add(String keyword);

  Future<void> remove(String keyword);

  Future<void> clear();
}
