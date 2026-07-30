import '../../application/source_market/source_market_port.dart';
import '../../data/builtin_book_sources.dart';
import '../../domain/source/book_source.dart';

/// 从应用内置资源读取书源市场数据。
final class BuiltinSourceMarketPort implements SourceMarketPort {
  const BuiltinSourceMarketPort();

  @override
  Future<List<BookSource>> loadSources() {
    return BuiltinBookSources.load();
  }
}
