import 'package:legado_flutter/domain/source/book_source.dart';

/// 书源详情用例所需的引擎端口。
///
/// 规则执行和 FRB 绑定由 infrastructure 适配器提供，业务门面不直接依赖
/// 生成绑定；返回结构保持现有 BookSourceService 契约。
abstract interface class BookSourceBookInfoPort {
  Future<Map<String, String>> getBookInfo(BookSource source, String bookUrl);
}
