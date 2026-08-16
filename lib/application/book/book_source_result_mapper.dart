import 'package:legado_flutter/domain/book/book.dart';

/// 将书源搜索/发现结果转换为页面使用的领域书籍。
List<Book> mapBookSourceResults(
  List<Map<String, String>> results,
  String sourceUrl,
) {
  return results
      .map(
        (result) => Book(
          id: '${sourceUrl}_${result['url'].hashCode}',
          name: result['name'] ?? '未知书名',
          author: result['author'] ?? '',
          coverUrl: result['coverUrl'] ?? '',
          sourceUrl: result['url'] ?? '',
          description: result['note'] ?? '',
          bookSourceUrl: sourceUrl,
        ),
      )
      .toList();
}
