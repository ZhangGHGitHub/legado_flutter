import '../models/book_source.dart';

List<BookSource> sourcesInManualOrder(List<BookSource> all) {
  final ordered = List<BookSource>.from(all);
  ordered.sort((a, b) {
    final byOrder = a.customOrder.compareTo(b.customOrder);
    if (byOrder != 0) return byOrder;
    return a.bookSourceUrl.compareTo(b.bookSourceUrl);
  });
  return ordered;
}

Map<String, int> customOrdersAfterMoveToTop(
  List<BookSource> all,
  Set<String> selected,
) {
  final sel = all.where((s) => selected.contains(s.bookSourceUrl)).toList();
  final rest = all.where((s) => !selected.contains(s.bookSourceUrl)).toList();
  final ordered = [...sel, ...rest];
  return {
    for (var i = 0; i < ordered.length; i++) ordered[i].bookSourceUrl: i,
  };
}

Map<String, int> customOrdersAfterMoveToBottom(
  List<BookSource> all,
  Set<String> selected,
) {
  final rest = all.where((s) => !selected.contains(s.bookSourceUrl)).toList();
  final sel = all.where((s) => selected.contains(s.bookSourceUrl)).toList();
  final ordered = [...rest, ...sel];
  return {
    for (var i = 0; i < ordered.length; i++) ordered[i].bookSourceUrl: i,
  };
}
