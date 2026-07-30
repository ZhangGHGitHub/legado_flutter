import '../../application/search/search_history_port.dart';
import '../../services/search_history.dart';

/// 使用现有 SharedPreferences 搜索历史实现的应用层适配器。
final class SharedPreferencesSearchHistoryAdapter
    implements SearchHistoryPort {
  const SharedPreferencesSearchHistoryAdapter();

  @override
  Future<List<String>> load() => SearchHistory.load();

  @override
  Future<void> add(String keyword) => SearchHistory.add(keyword);

  @override
  Future<void> remove(String keyword) => SearchHistory.remove(keyword);

  @override
  Future<void> clear() => SearchHistory.clear();
}
