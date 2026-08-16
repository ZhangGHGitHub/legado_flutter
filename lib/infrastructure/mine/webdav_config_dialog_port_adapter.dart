import '../../application/mine/webdav_config_dialog_port.dart';
import '../../domain/ports/webdav_repository.dart';
import '../../services/webdav_prefs.dart' as prefs_service;
import '../../services/webdav_setup_service.dart' as setup_service;
import '../bookshelf/shared_preferences_webdav_prefs_port_adapter.dart';

/// 将 WebDAV 配置对话框的存储和连接初始化接入既有 service。
final class WebDavConfigDialogPortAdapter implements WebDavConfigDialogPort {
  WebDavConfigDialogPortAdapter({
    required WebDavRepository repository,
    WebDavPrefsPort? prefs,
  }) : _repository = repository,
       _prefs = prefs ?? const SharedPreferencesWebDavPrefsPortAdapter();

  final WebDavRepository _repository;
  final WebDavPrefsPort _prefs;

  @override
  Future<WebDavConfig> load() => _prefs.load();

  @override
  Future<void> save(WebDavConfig config) =>
      prefs_service.WebDavPrefs.save(config);

  @override
  Future<void> initialize(WebDavConfig config) =>
      setup_service.WebDavSetupService.initialize(
        config,
        repository: _repository,
      );
}
