import '../../models/book_source.dart';
import '../database_helper.dart';

/// 书源 DAO — 薄封装 [DatabaseHelper]（不引入第二套存储栈）
class SourceDao {
  SourceDao([DatabaseHelper? db]) : _db = db ?? DatabaseHelper();

  final DatabaseHelper _db;

  Future<void> upsert(BookSource source) => _db.insertBookSource(source);

  Future<void> upsertAll(List<BookSource> sources) =>
      _db.insertBookSources(sources);

  Future<void> update(BookSource source) => _db.updateBookSource(source);

  Future<List<BookSource>> getAll() => _db.getBookSources();

  Future<List<BookSource>> getEnabled() => _db.getEnabledSources();

  Future<void> toggle(String url, bool enabled) =>
      _db.toggleSource(url, enabled);

  Future<void> delete(String url) => _db.deleteSource(url);
}
