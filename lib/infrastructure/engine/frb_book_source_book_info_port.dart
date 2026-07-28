import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_book_info_port.dart';
import '../../models/book_source.dart';

/// Rust/FRB 书源详情适配器。
class FrbBookSourceBookInfoPort implements BookSourceBookInfoPort {
  @override
  Future<Map<String, String>> getBookInfo(BookSource source, String bookUrl) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    return LegadoEngineBridge.getBookInfo(source, bookUrl);
  }
}
