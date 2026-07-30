import '../../application/preferences/click_action_prefs_port.dart';
import '../../models/click_zone.dart';
import '../../services/click_action_prefs.dart' as service;

/// 使用现有 SharedPreferences 键名保存点击区域配置。
final class SharedPreferencesClickActionPrefsAdapter
    implements ClickActionPrefsPort {
  const SharedPreferencesClickActionPrefsAdapter();

  @override
  Future<ClickZoneLayout> load() => service.ClickActionPrefs.load();

  @override
  Future<void> save(ClickZoneLayout layout) =>
      service.ClickActionPrefs.save(layout);

  @override
  Future<bool> isTipShown() => service.ClickActionPrefs.isTipShown();

  @override
  Future<void> markTipShown() => service.ClickActionPrefs.markTipShown();
}
