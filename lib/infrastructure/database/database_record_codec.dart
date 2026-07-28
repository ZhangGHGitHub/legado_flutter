import 'dart:convert';

import '../../models/book.dart';
import '../../models/chapter.dart';

/// Flutter 领域对象与 Rust SQLite JSON 记录之间的唯一编解码边界。
///
/// 领域模型仍保留自身的 JSON 能力以兼容备份和既有调用者，但数据库访问
/// 不再在 [DatabaseHelper] 中散落字段序列化和反序列化逻辑。
class DatabaseRecordCodec {
  const DatabaseRecordCodec._();

  static String encodeBook(Book book) => jsonEncode(book.toJson());

  static Book decodeBook(String record) {
    return Book.fromJson(_decodeMap(record, 'book'));
  }

  static String encodeChapters(List<Chapter> chapters) {
    return jsonEncode(chapters.map((chapter) => chapter.toJson()).toList());
  }

  static String encodeChapter(Chapter chapter, {bool clearDownloaded = false}) {
    final record = <String, dynamic>{
      ...chapter.toJson(),
      if (clearDownloaded) 'isDownloaded': false,
      if (clearDownloaded) 'content': null,
      if (clearDownloaded) 'clearDownloaded': true,
    };
    return jsonEncode([record]);
  }

  static Chapter decodeChapter(String record) {
    return Chapter.fromJson(_decodeMap(record, 'chapter'));
  }

  static Map<String, dynamic> _decodeMap(String record, String kind) {
    final value = jsonDecode(record);
    if (value is! Map) {
      throw FormatException('$kind database record must be a JSON object');
    }
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
