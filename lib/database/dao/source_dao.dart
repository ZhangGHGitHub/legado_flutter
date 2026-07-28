import '../../domain/repositories/book_source_repository.dart';
import '../../models/book_source.dart';
import '../database_helper.dart';

/// 书源 DAO — 薄封装 [DatabaseHelper]（不引入第二套存储栈）
class SourceDao implements BookSourceRepository {
  SourceDao([DatabaseHelper? db]) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  @override
  Future<void> upsert(BookSource source) => _db.insertBookSource(source);

  @override
  Future<void> upsertAll(List<BookSource> sources) =>
      _db.insertBookSources(sources);

  @override
  Future<void> update(BookSource source) => _db.updateBookSource(source);

  @override
  Future<List<BookSource>> getAll() => _db.getBookSources();

  @override
  Future<List<BookSource>> getEnabled() => _db.getEnabledSources();

  @override
  Future<void> toggle(String url, bool enabled) =>
      _db.toggleSource(url, enabled);

  @override
  Future<void> delete(String url) => _db.deleteSource(url);
}
