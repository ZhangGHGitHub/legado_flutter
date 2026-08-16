/// 公开 HTTP 文本资源的领域端口。
abstract interface class PublicTextFetchPort {
  Future<String> fetch(String url, {String userAgent = ''});
}
