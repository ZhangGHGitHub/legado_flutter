import '../../application/bookshelf/remote_book_sort_port.dart';
import '../../domain/remote/webdav_entry.dart' as domain;
import '../../services/remote_book_sort.dart' as service;

/// 将既有 RemoteBookSort 排序实现接入远程书籍应用端口。
final class RemoteBookSortPortAdapter implements RemoteBookSortPort {
  const RemoteBookSortPortAdapter();

  @override
  List<domain.WebDavEntry> sort(
    Iterable<domain.WebDavEntry> entries, {
    required RemoteBookSortMode mode,
    required bool ascending,
  }) => service.sortRemoteBookEntries(
    entries,
    mode: mode == RemoteBookSortMode.name
        ? service.RemoteBookSortMode.name
        : service.RemoteBookSortMode.time,
    ascending: ascending,
  );
}
