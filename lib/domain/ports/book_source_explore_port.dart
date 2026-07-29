import 'package:legado_flutter/domain/source/book_source.dart';

/// 书源发现用例所需的引擎端口。
///
/// 规则执行、结果字段映射和 FRB 绑定由 infrastructure 适配器提供；页码
/// 和返回列表保持现有 BookSourceService 契约。
abstract interface class BookSourceExplorePort {
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  });
}
