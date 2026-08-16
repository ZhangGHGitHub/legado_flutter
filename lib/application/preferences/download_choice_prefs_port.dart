/// 下载选项持久化边界。
abstract interface class DownloadChoicePrefsPort {
  Future<DownloadChoicePrefs> load();

  Future<bool> save({required int concurrency, required int nextN});
}

/// 下载选项的已持久化值。
final class DownloadChoicePrefs {
  const DownloadChoicePrefs({required this.concurrency, required this.nextN});

  final int concurrency;
  final int nextN;
}
