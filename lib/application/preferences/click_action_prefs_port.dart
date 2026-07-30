import '../../models/click_zone.dart';

/// 点击区域配置的应用层持久化边界。
abstract interface class ClickActionPrefsPort {
  Future<ClickZoneLayout> load();

  Future<void> save(ClickZoneLayout layout);

  Future<bool> isTipShown();

  Future<void> markTipShown();
}
