import '../models/book.dart';
import '../services/simulated_reading_prefs.dart';

/// 书架未读章评估 — 对齐 Jingshiro `totalChapterNum - durChapterIndex - 1`
class ShelfUnreadResult {
  final int? count;
  final bool highlight;

  const ShelfUnreadResult({this.count, this.highlight = false});

  const ShelfUnreadResult.hidden() : count = null, highlight = false;

  bool get visible =>
      (count != null && count! > 0) || (count == null && highlight);
}

abstract final class ShelfUnread {
  ShelfUnread._();

  static final _numRe = RegExp(r'(\d{1,6})');

  static ShelfUnreadResult evaluate({
    required Book book,
    int? totalChapters,
    int? durChapterIndex,
  }) {
    final hasTitleUpdate = _titleHasUpdate(book);
    var total = totalChapters;
    var durIdx = durChapterIndex;

    if (total != null && total > 0 && book.simReadEnabled) {
      total = SimulatedReadingConfig.fromBook(book)
          .simulatedTotalChapterNum(total);
    }

    if (total != null && total > 0 && durIdx != null && durIdx >= 0) {
      final unread = total - durIdx - 1;
      if (unread > 0) {
        return ShelfUnreadResult(
          count: unread,
          highlight: hasTitleUpdate,
        );
      }
      if (hasTitleUpdate) {
        return const ShelfUnreadResult(count: null, highlight: true);
      }
      return const ShelfUnreadResult.hidden();
    }

    return _fallbackFromTitles(book);
  }

  static bool _titleHasUpdate(Book book) {
    final last = book.lastChapter;
    final current = book.currentChapter;
    return last != null &&
        last.isNotEmpty &&
        current != null &&
        current.isNotEmpty &&
        last != current;
  }

  /// 章节名数字推算 — 无本地目录索引时的回退
  static ShelfUnreadResult _fallbackFromTitles(Book book) {
    final last = book.lastChapter;
    final current = book.currentChapter;
    final lastNum = _chapterNum(last);
    final curNum = _chapterNum(current);
    final hasUpdate = _titleHasUpdate(book);

    int? unread;
    if (lastNum != null && curNum != null && lastNum > curNum) {
      unread = lastNum - curNum;
    } else if (hasUpdate) {
      unread = null;
    } else {
      return const ShelfUnreadResult.hidden();
    }

    if (unread != null && unread <= 0 && !hasUpdate) {
      return const ShelfUnreadResult.hidden();
    }

    return ShelfUnreadResult(count: unread, highlight: hasUpdate);
  }

  static int? _chapterNum(String? s) {
    if (s == null || s.isEmpty) return null;
    final m = _numRe.firstMatch(s);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }
}
