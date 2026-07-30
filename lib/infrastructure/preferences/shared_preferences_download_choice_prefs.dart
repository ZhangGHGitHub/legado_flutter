import 'package:shared_preferences/shared_preferences.dart';

import '../../application/preferences/download_choice_prefs_port.dart';
import '../../application/preferences/shared_preferences_runtime.dart';

/// SharedPreferences adapter for the download choice preference boundary.
final class SharedPreferencesDownloadChoicePrefs
    implements DownloadChoicePrefsPort {
  const SharedPreferencesDownloadChoicePrefs(this._prefs);

  static const concurrencyKey = 'download_choice_concurrency';
  static const nextNKey = 'download_choice_next_n';
  static const defaultConcurrency = 1;
  static const defaultNextN = 50;
  static const minConcurrency = 1;
  static const maxConcurrency = 8;
  static const minNextN = 1;
  static const maxNextN = 9999;

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesDownloadChoicePrefs> loadFromRuntime() async {
    return SharedPreferencesDownloadChoicePrefs(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  Future<DownloadChoicePrefs> load() async {
    final prefs = _prefs;
    return DownloadChoicePrefs(
      concurrency: _clampConcurrency(
        prefs?.getInt(concurrencyKey) ?? defaultConcurrency,
      ),
      nextN: _clampNextN(prefs?.getInt(nextNKey) ?? defaultNextN),
    );
  }

  @override
  Future<bool> save({required int concurrency, required int nextN}) async {
    final prefs = _prefs;
    if (prefs == null) return false;
    final savedConcurrency = await prefs.setInt(
      concurrencyKey,
      _clampConcurrency(concurrency),
    );
    if (!savedConcurrency) return false;
    return prefs.setInt(nextNKey, _clampNextN(nextN));
  }

  static int _clampConcurrency(int value) =>
      value.clamp(minConcurrency, maxConcurrency);

  static int _clampNextN(int value) => value.clamp(minNextN, maxNextN);
}
