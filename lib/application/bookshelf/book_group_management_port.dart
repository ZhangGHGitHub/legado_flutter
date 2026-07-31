import '../../domain/book/book_group.dart';

/// 书架分组管理与选择 dialog 所需的应用端口。
///
/// 端口保留 [BookGroupStore] 的查询和写入语义，避免 widget 直接依赖
/// 持久化服务；组合根负责绑定具体实现。
abstract interface class BookGroupManagementPort {
  Future<List<BookGroup>> load();

  Future<List<BookGroup>> loadSelectGroups();

  Future<bool> canAddGroup();

  Future<int> unusedId();

  Future<int> maxOrder();

  Future<void> update(BookGroup group);

  Future<void> delete(BookGroup group);

  Future<void> syncNamesFromBooks(Iterable<String> names);
}
