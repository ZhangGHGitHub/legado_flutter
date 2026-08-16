/// 书源变量持久化端口。
abstract interface class SourceVariablePort {
  Future<String> read(String sourceUrl);

  Future<bool> write(String sourceUrl, String value);
}
