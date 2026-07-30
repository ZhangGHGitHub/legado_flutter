import '../../application/preferences/bookshelf_config_prefs_port.dart';
import '../../services/bookshelf_prefs.dart' as service;

/// 保留书架布局偏好既有键名、默认值和迁移语义的 adapter。
final class SharedPreferencesBookshelfConfigPrefsAdapter
    implements BookshelfConfigPrefsPort {
  const SharedPreferencesBookshelfConfigPrefsAdapter();

  @override
  Future<int> loadGroupStyle() => service.BookshelfPrefs.loadGroupStyle();
}
