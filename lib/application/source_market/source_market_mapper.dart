import 'package:legado_flutter/domain/source/book_source.dart';

/// 将内置书源整理为市场分组，保留原有展示顺序和空导入分组。
abstract final class SourceMarketMapper {
  static const communityImportGroup = '📥 从社区导入';

  static Map<String, List<BookSource>> fromSources(List<BookSource> sources) {
    final market = <String, List<BookSource>>{};
    for (final source in sources) {
      market.putIfAbsent(source.bookSourceGroup, () => []).add(source);
    }
    market[communityImportGroup] = [];
    return market;
  }
}
