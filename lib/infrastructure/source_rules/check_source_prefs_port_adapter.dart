import '../../application/source_rules/check_source_prefs_port.dart';
import '../../services/check_source_prefs.dart' as service;

/// Preserves the existing source-check preference keys and defaults.
final class CheckSourcePrefsPortAdapter implements CheckSourcePrefsPort {
  const CheckSourcePrefsPortAdapter();

  @override
  Future<int> timeoutSec() => service.CheckSourcePrefs.timeoutSec();

  @override
  Future<void> setTimeoutSec(int value) =>
      service.CheckSourcePrefs.setTimeoutSec(value);

  @override
  Future<bool> checkSearch() => service.CheckSourcePrefs.checkSearch();

  @override
  Future<void> setCheckSearch(bool value) =>
      service.CheckSourcePrefs.setCheckSearch(value);

  @override
  Future<bool> checkDiscovery() => service.CheckSourcePrefs.checkDiscovery();

  @override
  Future<void> setCheckDiscovery(bool value) =>
      service.CheckSourcePrefs.setCheckDiscovery(value);

  @override
  Future<bool> checkToc() => service.CheckSourcePrefs.checkToc();

  @override
  Future<void> setCheckToc(bool value) =>
      service.CheckSourcePrefs.setCheckToc(value);

  @override
  Future<bool> checkContent() => service.CheckSourcePrefs.checkContent();

  @override
  Future<void> setCheckContent(bool value) =>
      service.CheckSourcePrefs.setCheckContent(value);

  @override
  Future<bool> showDebugMessage() =>
      service.CheckSourcePrefs.showDebugMessage();

  @override
  Future<void> setShowDebugMessage(bool value) =>
      service.CheckSourcePrefs.setShowDebugMessage(value);

  @override
  Future<String> lastKeyword() => service.CheckSourcePrefs.lastKeyword();

  @override
  Future<void> setLastKeyword(String value) =>
      service.CheckSourcePrefs.setLastKeyword(value);
}
