import '../../models/book.dart';
import '../../models/book_source.dart';
import '../../models/chapter.dart';

/// 书源目录用例所需的引擎端口。
///
/// 规则执行和 FRB 绑定由 infrastructure 适配器提供，业务门面不直接依赖
/// 生成绑定；返回章节的顺序和 index 保持现有 BookSourceService 契约。
abstract interface class BookSourceTocPort {
  Future<List<Chapter>> getToc(BookSource source, Book book);
}
