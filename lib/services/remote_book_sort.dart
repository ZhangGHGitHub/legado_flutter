import '../domain/remote/webdav_entry.dart';

enum RemoteBookSortMode { name, time }

List<WebDavEntry> sortRemoteBookEntries(
  Iterable<WebDavEntry> entries, {
  required RemoteBookSortMode mode,
  required bool ascending,
}) {
  final sorted = entries.toList(growable: false);
  sorted.sort((a, b) {
    if (a.isDir != b.isDir) return a.isDir ? -1 : 1;

    final comparison = mode == RemoteBookSortMode.name
        ? _compareNames(a.name, b.name)
        : a.lastModified.compareTo(b.lastModified);
    final tieBreak = comparison == 0
        ? _compareNames(a.name, b.name)
        : comparison;
    return ascending ? tieBreak : -tieBreak;
  });
  return sorted;
}

int _compareNames(String left, String right) =>
    left.toLowerCase().compareTo(right.toLowerCase());
