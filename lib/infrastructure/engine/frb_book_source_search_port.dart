import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_search_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

/// Rust/FRB 书源搜索适配器。
class FrbBookSourceSearchPort implements BookSourceSearchPort {
  @override
  Future<List<Map<String, String>>> search(BookSource source, String keyword) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    return LegadoEngineBridge.search(source, keyword);
  }
}
