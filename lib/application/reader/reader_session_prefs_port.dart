/// 阅读会话运行时偏好的应用层持久化边界。
abstract interface class ReaderSessionPrefsPort {
  Future<bool> loadEnableReplace();

  Future<void> saveEnableReplace(bool value);
}
