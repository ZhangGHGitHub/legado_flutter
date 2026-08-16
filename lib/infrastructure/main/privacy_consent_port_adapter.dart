import 'package:shared_preferences/shared_preferences.dart';

import '../../application/main/privacy_consent_port.dart';
import '../../application/preferences/shared_preferences_runtime.dart';

/// SharedPreferences adapter for the legacy privacy-consent preference.
final class SharedPreferencesPrivacyConsentPortAdapter
    implements PrivacyConsentPort {
  const SharedPreferencesPrivacyConsentPortAdapter(this._prefs);

  static const acceptedKey = 'legado_privacy_accepted';

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesPrivacyConsentPortAdapter> create() async {
    return SharedPreferencesPrivacyConsentPortAdapter(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  Future<SharedPreferences?> _resolvePrefs() async =>
      _prefs ?? await SharedPreferencesRuntime.getOrNull();

  @override
  Future<bool> isAccepted() async {
    try {
      final prefs = await _resolvePrefs();
      return prefs?.getBool(acceptedKey) == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> saveAccepted() async {
    final prefs = await _resolvePrefs();
    if (prefs == null) return false;
    try {
      return await prefs.setBool(acceptedKey, true);
    } catch (_) {
      return false;
    }
  }
}
