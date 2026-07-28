import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/local_book_parser_port.dart';

/// Rust/FRB 本地书籍解析适配器。
class FrbLocalBookParserPort implements LocalBookParserPort {
  const FrbLocalBookParserPort();

  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  List<LocalBookChapterSnapshot> parseTxtChapters(String content) {
    if (!isAvailable) throw StateError('Rust engine not available');
    return LegadoEngineBridge.parseTxtChapters(content)
        .map(
          (chapter) => LocalBookChapterSnapshot(
            title: chapter.title,
            content: chapter.content,
          ),
        )
        .toList(growable: false);
  }

  @override
  LocalBookEpubSnapshot parseEpub(List<int> data) {
    if (!isAvailable) throw StateError('Rust engine not available');
    final result = LegadoEngineBridge.parseEpub(data);
    return LocalBookEpubSnapshot(
      title: result.title,
      author: result.author,
      chapters: result.chapters
          .map(
            (chapter) => LocalBookChapterSnapshot(
              title: chapter.title,
              content: chapter.content,
            ),
          )
          .toList(growable: false),
    );
  }
}
