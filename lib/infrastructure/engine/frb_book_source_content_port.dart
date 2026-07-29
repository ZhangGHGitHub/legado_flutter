import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_content_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

/// Rust/FRB 书源正文适配器。
class FrbBookSourceContentPort
    implements BookSourceContentPort, PaginatedBookSourceContentPort {
  @override
  Future<String> getContent(BookSource source, String chapterUrl) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    return LegadoEngineBridge.getContent(source, chapterUrl);
  }

  @override
  Future<String> getContentWithNextChapter(
    BookSource source,
    String chapterUrl, {
    String? nextChapterUrl,
  }) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    return LegadoEngineBridge.getContent(
      source,
      chapterUrl,
      nextChapterUrl: nextChapterUrl,
    );
  }
}
