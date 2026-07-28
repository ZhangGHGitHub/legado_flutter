import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_explore_port.dart';
import '../../models/book_source.dart';

/// Rust/FRB 书源发现适配器。
class FrbBookSourceExplorePort implements BookSourceExplorePort {
  @override
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) {
    if (!LegadoEngineBridge.isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    return LegadoEngineBridge.explore(source, exploreUrl, page: page);
  }
}
