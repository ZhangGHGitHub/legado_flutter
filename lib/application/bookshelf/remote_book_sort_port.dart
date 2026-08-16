import '../../domain/remote/webdav_entry.dart';

enum RemoteBookSortMode { name, time }

/// 远程书籍列表排序所需的应用端口。
abstract interface class RemoteBookSortPort {
  List<WebDavEntry> sort(
    Iterable<WebDavEntry> entries, {
    required RemoteBookSortMode mode,
    required bool ascending,
  });
}
