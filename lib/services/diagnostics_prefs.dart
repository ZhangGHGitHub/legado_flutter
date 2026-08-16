import '../application/preferences/shared_preferences_runtime.dart';

abstract final class DiagnosticsPrefs {
  static const _enabledKey = 'diagnostics_monitor_enabled';

  static Future<bool> isMonitoringEnabled() async {
    try {
      final prefs = await SharedPreferencesRuntime.getOrNull();
      return prefs?.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setMonitoringEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferencesRuntime.getOrNull();
      await prefs?.setBool(_enabledKey, enabled);
    } catch (_) {}
  }
}
