/// Application boundary for source validation preferences.
abstract interface class CheckSourcePrefsPort {
  Future<int> timeoutSec();

  Future<void> setTimeoutSec(int value);

  Future<bool> checkSearch();

  Future<void> setCheckSearch(bool value);

  Future<bool> checkDiscovery();

  Future<void> setCheckDiscovery(bool value);

  Future<bool> checkToc();

  Future<void> setCheckToc(bool value);

  Future<bool> checkContent();

  Future<void> setCheckContent(bool value);

  Future<bool> showDebugMessage();

  Future<void> setShowDebugMessage(bool value);

  Future<String> lastKeyword();

  Future<void> setLastKeyword(String value);
}

/// Fallback used until the composition root supplies the persistent adapter.
final class UnavailableCheckSourcePrefsPort implements CheckSourcePrefsPort {
  const UnavailableCheckSourcePrefsPort();

  @override
  Future<int> timeoutSec() => Future.value(30);

  @override
  Future<void> setTimeoutSec(int value) async {}

  @override
  Future<bool> checkSearch() => Future.value(true);

  @override
  Future<void> setCheckSearch(bool value) async {}

  @override
  Future<bool> checkDiscovery() => Future.value(true);

  @override
  Future<void> setCheckDiscovery(bool value) async {}

  @override
  Future<bool> checkToc() => Future.value(true);

  @override
  Future<void> setCheckToc(bool value) async {}

  @override
  Future<bool> checkContent() => Future.value(true);

  @override
  Future<void> setCheckContent(bool value) async {}

  @override
  Future<bool> showDebugMessage() => Future.value(true);

  @override
  Future<void> setShowDebugMessage(bool value) async {}

  @override
  Future<String> lastKeyword() => Future.value('');

  @override
  Future<void> setLastKeyword(String value) async {}
}
