import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/annotation/bookmark_snapshot.dart';
import '../domain/ports/bookmark_port.dart';
import 'app_log.dart';

/// 独立书签服务；字段对齐 Jingshiro Bookmark。
class BookmarkService {
  static BookmarkPort? _configuredBookmarkPort;

  static BookmarkPort get _bookmarkPort =>
      _configuredBookmarkPort ??
      (throw StateError('BookmarkService 尚未配置 BookmarkPort'));

  static bool get isReady => _configuredBookmarkPort?.isAvailable ?? false;

  static void configureBookmarkPort(BookmarkPort port) {
    _configuredBookmarkPort = port;
  }

  @visibleForTesting
  static void resetBookmarkPort() {
    _configuredBookmarkPort = null;
  }

  static List<BookmarkSnapshot> list({String? bookId}) {
    if (!isReady) return [];
    try {
      return _bookmarkPort.list(bookId: bookId);
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.list: $e'));
      return [];
    }
  }

  static List<BookmarkSnapshot> listSnapshots({String? bookId}) {
    if (!isReady) return const [];
    try {
      return _bookmarkPort.list(bookId: bookId);
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.listSnapshots: $e'));
      return const [];
    }
  }

  /// 保存书签并返回时间戳主键；写入失败返回 null。
  static int? save({
    int? time,
    required String bookId,
    required String bookName,
    required String bookAuthor,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String bookText,
    String content = '',
  }) {
    if (!isReady) return null;
    final bookmarkTime = time ?? DateTime.now().millisecondsSinceEpoch;
    try {
      final saved = _bookmarkPort.save(
        BookmarkSnapshot(
          time: bookmarkTime,
          bookId: bookId,
          bookName: bookName,
          bookAuthor: bookAuthor,
          chapterIndex: chapterIndex,
          chapterPos: chapterPos,
          chapterName: chapterName,
          bookText: bookText,
          content: content,
        ),
      );
      if (!saved) return null;
      return bookmarkTime;
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.save: $e'));
      return null;
    }
  }

  static void delete(int time) {
    if (!isReady) return;
    try {
      _bookmarkPort.delete(time);
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.delete: $e'));
    }
  }

  static String exportJson({String? bookId}) {
    return encodeJson(list(bookId: bookId));
  }

  /// 合并本地与远端书签；时间主键冲突时保留远端记录。
  static List<BookmarkSnapshot> mergeRemote(
    Iterable<BookmarkSnapshot> local,
    Iterable<BookmarkSnapshot> remote,
  ) {
    final merged = <int, BookmarkSnapshot>{
      for (final bookmark in local) bookmark.time: bookmark,
    };
    for (final bookmark in remote) {
      merged[bookmark.time] = bookmark;
    }
    return merged.values.toList(growable: false);
  }

  /// 合并原版 bookmark.json；重复时间主键按远端最后写入语义处理。
  static String mergeRemoteJson(String localRaw, String remoteRaw) {
    return encodeJson(mergeRemote(decodeJson(localRaw), decodeJson(remoteRaw)));
  }

  /// 编码为原版 bookmark.json 的数组格式，并保留本地 bookId 扩展。
  static String encodeJson(Iterable<BookmarkSnapshot> bookmarks) {
    final items = bookmarks
        .map(
          (bookmark) => {
            'time': bookmark.time,
            'bookId': bookmark.bookId,
            'bookName': bookmark.bookName,
            'bookAuthor': bookmark.bookAuthor,
            'chapterIndex': bookmark.chapterIndex,
            'chapterPos': bookmark.chapterPos,
            'chapterName': bookmark.chapterName,
            'bookText': bookmark.bookText,
            'content': bookmark.content,
          },
        )
        .toList(growable: false);
    return const JsonEncoder.withIndent('  ').convert(items);
  }

  /// 解码原版或本地扩展的 bookmark.json；缺失主键或非数组直接拒绝。
  static List<BookmarkSnapshot> decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('书签文件必须是数组');
    }
    return decoded
        .map((item) {
          if (item is! Map) {
            throw const FormatException('书签条目必须是对象');
          }
          final time = (item['time'] as num?)?.toInt();
          if (time == null || time <= 0) {
            throw const FormatException('书签缺少有效 time');
          }
          String text(String key) => item[key] as String? ?? '';
          int number(String key, [int fallback = 0]) =>
              (item[key] as num?)?.toInt() ?? fallback;
          return BookmarkSnapshot(
            time: time,
            bookId: text('bookId'),
            bookName: text('bookName'),
            bookAuthor: text('bookAuthor'),
            chapterIndex: number('chapterIndex'),
            chapterPos: number('chapterPos'),
            chapterName: text('chapterName'),
            bookText: text('bookText'),
            content: text('content'),
          );
        })
        .toList(growable: false);
  }

  /// 按时间主键幂等导入；同一文件内重复主键取最后一项。
  static int importJson(String raw) {
    if (!isReady) return 0;
    final decoded = decodeJson(raw);
    final unique = <int, BookmarkSnapshot>{
      for (final bookmark in decoded) bookmark.time: bookmark,
    };
    var imported = 0;
    for (final bookmark in unique.values) {
      if (save(
            time: bookmark.time,
            bookId: bookmark.bookId,
            bookName: bookmark.bookName,
            bookAuthor: bookmark.bookAuthor,
            chapterIndex: bookmark.chapterIndex,
            chapterPos: bookmark.chapterPos,
            chapterName: bookmark.chapterName,
            bookText: bookmark.bookText,
            content: bookmark.content,
          ) !=
          null) {
        imported++;
      }
    }
    return imported;
  }
}
