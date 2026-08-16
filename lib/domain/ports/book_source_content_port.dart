import 'package:legado_flutter/domain/source/book_source.dart';

/// 书源正文用例所需的引擎端口。
///
/// 规则执行和 FRB 绑定由 infrastructure 适配器提供；正文文本由端口原样
/// 返回，换行和分页交给上层既有阅读管线处理。
abstract interface class BookSourceContentPort {
  Future<String> getContent(BookSource source, String chapterUrl);
}

abstract interface class PaginatedBookSourceContentPort {
  Future<String> getContentWithNextChapter(
    BookSource source,
    String chapterUrl, {
    String? nextChapterUrl,
  });
}
