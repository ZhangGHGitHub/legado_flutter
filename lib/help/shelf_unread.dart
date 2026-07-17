import '../models/book.dart';
import '../services/simulated_reading_prefs.dart';

/// 书架未读章评估 — 对齐 Jingshiro `totalChapterNum - durChapterIndex - 1`
///
/// - **未读数**：有 total/dur 时用精确公式；否则章节名数字 fallback
/// - **高亮（有更新）**：`lastChapter != currentChapter`，与未读数正交
class ShelfUnreadResult {
  final int? count;
  final bool highlight;

  const ShelfUnreadResult({this.count, this.highlight = false});

  const ShelfUnreadResult.hidden() : count = null, highlight = false;

  bool get visible =>
      (count != null && count! > 0) || (count == null && highlight);

  /// 是否为「有更新」样式（与「未读章数」区分；主壳待更新角标勿混用）
  bool get hasUpdate => highlight;
}

abstract final class ShelfUnread {
  ShelfUnread._();

  static final _numRe = RegExp(r'(\d{1,6})');

  /// 统一未读数：优先精确章索引，缺数据时安全 fallback。
  ///
  /// [totalChapters] / [durChapterIndex] 可覆盖 [book] 持久化字段
  ///（例如内存目录 meta）。
  static ShelfUnreadResult evaluate({
    required Book book,
    int? totalChapters,
    int? durChapterIndex,
  }) {
    final hasTitleUpdate = _titleHasUpdate(book);
    final total = _resolveTotal(book, totalChapters);
    final durIdx = _resolveDurIndex(book, total, durChapterIndex);

    if (total != null && total > 0 && durIdx != null && durIdx >= 0) {
      var effectiveTotal = total;
      if (book.simReadEnabled) {
        effectiveTotal = SimulatedReadingConfig.fromBook(book)
            .simulatedTotalChapterNum(total);
      }
      final unread = effectiveTotal - durIdx - 1;
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

  static int? _resolveTotal(Book book, int? override) {
    if (override != null && override > 0) return override;
    if (book.totalChapterNum > 0) return book.totalChapterNum;
    return null;
  }

  static int? _resolveDurIndex(Book book, int? total, int? override) {
    if (override != null && override >= 0) return override;
    // 有总章数即可用持久化索引（含 0 = 第一章）
    if (total != null && total > 0) return book.durChapterIndex.clamp(0, total - 1);
    return null;
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

  /// 章节名数字推算 — 无 total/dur 时的回退（不准确，仅兜底）
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
