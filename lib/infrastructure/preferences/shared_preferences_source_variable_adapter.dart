import 'package:shared_preferences/shared_preferences.dart';

import '../../application/preferences/shared_preferences_runtime.dart';
import '../../application/preferences/source_variable_port.dart';

final class SharedPreferencesSourceVariableAdapter
    implements SourceVariablePort {
  const SharedPreferencesSourceVariableAdapter(this._prefs);

  static const keyPrefix = 'source_variable:';

  final SharedPreferences? _prefs;

  static Future<SharedPreferencesSourceVariableAdapter> create() async {
    return SharedPreferencesSourceVariableAdapter(
      await SharedPreferencesRuntime.getOrNull(),
    );
  }

  @override
  Future<String> read(String sourceUrl) async =>
      _prefs?.getString(_key(sourceUrl)) ?? '';

  @override
  Future<bool> write(String sourceUrl, String value) async =>
      _prefs?.setString(_key(sourceUrl), value) ?? false;

  static String _key(String sourceUrl) => '$keyPrefix$sourceUrl';
}
