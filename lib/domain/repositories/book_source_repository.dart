import '../../models/book_source.dart';

/// 书源领域存储端口。
///
/// 书源管理和启动初始化只依赖该契约，具体数据库实现由 infrastructure/DAO
/// 提供，避免页面直接接触数据库管理器。
abstract interface class BookSourceRepository {
  Future<void> upsert(BookSource source);

  Future<void> upsertAll(List<BookSource> sources);

  Future<void> update(BookSource source);

  Future<List<BookSource>> getAll();

  Future<List<BookSource>> getEnabled();

  Future<void> toggle(String url, bool enabled);

  Future<void> delete(String url);
}
