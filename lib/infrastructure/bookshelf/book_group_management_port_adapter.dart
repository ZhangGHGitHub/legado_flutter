import '../../application/bookshelf/book_group_management_port.dart';
import '../../domain/book/book_group.dart';
import '../../services/book_group_store.dart';

/// 将现有 [BookGroupStore] 的键名、排序和同步行为暴露给 dialog 端口。
final class BookGroupManagementPortAdapter implements BookGroupManagementPort {
  const BookGroupManagementPortAdapter();

  @override
  Future<List<BookGroup>> load() => BookGroupStore.load();

  @override
  Future<List<BookGroup>> loadSelectGroups() =>
      BookGroupStore.loadSelectGroups();

  @override
  Future<bool> canAddGroup() => BookGroupStore.canAddGroup();

  @override
  Future<int> unusedId() => BookGroupStore.unusedId();

  @override
  Future<int> maxOrder() => BookGroupStore.maxOrder();

  @override
  Future<void> update(BookGroup group) => BookGroupStore.update(group);

  @override
  Future<void> delete(BookGroup group) => BookGroupStore.delete(group);

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) =>
      BookGroupStore.syncNamesFromBooks(names);
}
