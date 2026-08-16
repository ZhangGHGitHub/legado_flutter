import 'package:shared_preferences/shared_preferences.dart';

import '../../application/bookshelf/remote_book_help_port.dart';

/// 对齐原版 `LocalConfig.webDavBookHelpVersionIsLast` 的版本偏好。
final class SharedPreferencesRemoteBookHelpPortAdapter
    implements RemoteBookHelpPort {
  const SharedPreferencesRemoteBookHelpPortAdapter();

  static const _version = 1;
  static const _versionKey = 'webDavBookHelpVersion';
  static const _legacyFirstOpenKey = 'firstOpenWebDavBook';

  @override
  Future<bool> shouldAutoShow() async {
    final prefs = await SharedPreferences.getInstance();
    var version = prefs.getInt(_versionKey) ?? 0;
    if (version == 0 && prefs.containsKey(_legacyFirstOpenKey)) {
      if (!(prefs.getBool(_legacyFirstOpenKey) ?? true)) version = _version;
    }
    if (version >= _version) return false;
    await prefs.setInt(_versionKey, _version);
    return true;
  }
}
