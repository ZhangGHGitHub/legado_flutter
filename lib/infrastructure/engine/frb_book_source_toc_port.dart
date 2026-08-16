import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_toc_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';

/// Rust/FRB 书源目录适配器。
class FrbBookSourceTocPort implements BookSourceTocPort {
  @override
  Future<List<Chapter>> getToc(BookSource source, Book book) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    return LegadoEngineBridge.getToc(source, book);
  }
}
