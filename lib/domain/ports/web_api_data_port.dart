/// 本地 Web API 路由所需的业务数据边界。
///
/// HTTP 监听、认证和响应属于平台基础设施；书籍、目录、书源和阅读统计查询
/// 必须通过该端口进入应用层。
abstract interface class WebApiDataPort {
  bool get isAvailable;

  Future<List<Map<String, dynamic>>> listBooks();

  Future<void> addBook(Map<String, dynamic> book);

  Future<void> deleteBook(String bookId);

  Future<List<Map<String, dynamic>>> listChapters(String bookId);

  Future<List<Map<String, dynamic>>> listSources();

  Future<Map<String, dynamic>> readingStats();
}

class WebApiDataUnavailable implements Exception {
  const WebApiDataUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}
