import 'dart:async';
import 'dart:convert';

import '../bridge/legado_db_bridge.dart';
import '../bridge/legado_engine_bridge.dart';
import 'app_log.dart';
import '../src/rust/api.dart' as rust_api;

/// 独立书签服务；字段对齐 Jingshiro Bookmark。
class BookmarkService {
  static bool get isReady =>
      LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;

  static List<rust_api.BookmarkDto> list({String? bookId}) {
    if (!isReady) return [];
    try {
      return rust_api.listBookmarks(bookId: bookId ?? '');
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.list: $e'));
      return [];
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
      rust_api.upsertBookmark(
        time: bookmarkTime,
        bookId: bookId,
        bookName: bookName,
        bookAuthor: bookAuthor,
        chapterIndex: chapterIndex,
        chapterPos: chapterPos,
        chapterName: chapterName,
        bookText: bookText,
        content: content,
      );
      return bookmarkTime;
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.save: $e'));
      return null;
    }
  }

  static void delete(int time) {
    if (!isReady) return;
    try {
      rust_api.deleteBookmark(time: time);
    } catch (e) {
      unawaited(AppLog.e('BookmarkService.delete: $e'));
    }
  }

  static String exportJson({String? bookId}) {
    return encodeJson(list(bookId: bookId));
  }

  /// 合并本地与远端书签；时间主键冲突时保留远端记录。
  static List<rust_api.BookmarkDto> mergeRemote(
    Iterable<rust_api.BookmarkDto> local,
    Iterable<rust_api.BookmarkDto> remote,
  ) {
    final merged = <int, rust_api.BookmarkDto>{
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
  static String encodeJson(Iterable<rust_api.BookmarkDto> bookmarks) {
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
  static List<rust_api.BookmarkDto> decodeJson(String raw) {
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
          return rust_api.BookmarkDto(
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
    final unique = <int, rust_api.BookmarkDto>{
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
