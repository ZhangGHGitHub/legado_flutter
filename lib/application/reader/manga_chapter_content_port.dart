import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';
import 'reader_chapter_content_port.dart';

/// 漫画阅读页读取章节原始正文所需的应用端口。
abstract interface class MangaChapterContentPort {
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  });
}

/// 独立宿主未提供漫画正文读取能力时的明确空实现。
final class EmptyMangaChapterContentPort implements MangaChapterContentPort {
  const EmptyMangaChapterContentPort();

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) => Future<String>.error(UnsupportedError('漫画正文服务不可用'));
}

/// 将现有通用正文端口桥接为漫画阅读页端口，供未显式注入端口的旧入口兼容使用。
final class ReaderBackedMangaChapterContentPort
    implements MangaChapterContentPort {
  const ReaderBackedMangaChapterContentPort(this._readerPort);

  final ReaderChapterContentPort _readerPort;

  @override
  Future<String> loadChapterContent({
    required Book book,
    required Chapter chapter,
  }) async {
    final content = await _readerPort.loadChapterContent(
      book: book,
      chapter: chapter,
    );
    if (content == '未找到匹配的书源') {
      throw StateError('未找到书源，无法加载漫画页');
    }
    return content;
  }
}
