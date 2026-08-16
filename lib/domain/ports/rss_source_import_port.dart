/// RSS 订阅源 URL 内容读取端口。
abstract interface class RssSourceImportPort {
  Future<String?> fetch(String url);
}
