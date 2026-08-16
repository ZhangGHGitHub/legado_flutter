import 'dart:io';

import 'package:path/path.dart' as p;

import '../../application/mine/my_page_port.dart';
import '../../domain/web_api_status.dart';
import '../../services/backup_service.dart';
import '../../services/database_status_service.dart';
import '../../services/engine_status_service.dart';
import '../../services/web_api_prefs.dart';
import '../../services/web_api_service.dart';

typedef MyPageWebApiConfigLoader = Future<WebApiConfig> Function();
typedef MyPageWebApiToggler = Future<WebApiStatus?> Function(bool enabled);
typedef MyPageWebApiStatusReader = WebApiStatus? Function();
typedef MyPageBackup = Future<File> Function();
typedef MyPageBoolReader = bool Function();
typedef MyPageStringReader = String Function();

/// 将既有服务和平台状态映射为 MyPagePort。
final class MyPagePortAdapter implements MyPagePort {
  MyPagePortAdapter({
    BackupService? backupService,
    MyPageWebApiConfigLoader? loadWebApiConfig,
    MyPageWebApiToggler? toggleWebApi,
    MyPageWebApiStatusReader? currentWebApiStatus,
    MyPageBackup? backupToLocalFile,
    MyPageBoolReader? isEngineAvailable,
    MyPageBoolReader? isDatabaseReady,
    MyPageStringReader? engineVersion,
  }) : _loadWebApiConfig = loadWebApiConfig ?? WebApiPrefs.load,
       _toggleWebApi = toggleWebApi ?? WebApiService.setEnabled,
       _currentWebApiStatus =
           currentWebApiStatus ?? WebApiService.currentStatus,
       _backupToLocalFile =
           backupToLocalFile ??
           backupService?.backupToLocalFile ??
           _backupWithService,
       _isEngineAvailable = isEngineAvailable ?? _readEngineAvailability,
       _isDatabaseReady = isDatabaseReady ?? _readDatabaseReadiness,
       _engineVersion = engineVersion ?? _readEngineVersion;

  final MyPageWebApiConfigLoader _loadWebApiConfig;
  final MyPageWebApiToggler _toggleWebApi;
  final MyPageWebApiStatusReader _currentWebApiStatus;
  final MyPageBackup _backupToLocalFile;
  final MyPageBoolReader _isEngineAvailable;
  final MyPageBoolReader _isDatabaseReady;
  final MyPageStringReader _engineVersion;

  @override
  bool get isEngineAvailable => _isEngineAvailable();

  @override
  bool get isDatabaseReady => _isDatabaseReady();

  @override
  String get engineVersion => _engineVersion();

  @override
  Future<MyPageWebServiceStatus> loadWebService() async {
    final config = await _loadWebApiConfig();
    return _status(config.enabled, _currentWebApiStatus());
  }

  @override
  Future<MyPageWebServiceStatus> toggleWebService() async {
    final config = await _loadWebApiConfig();
    await _toggleWebApi(!config.enabled);
    return loadWebService();
  }

  @override
  Future<String> backupLocally() async {
    final file = await _backupToLocalFile();
    return p.basename(file.path);
  }

  static MyPageWebServiceStatus _status(bool enabled, WebApiStatus? status) {
    final running = enabled && (status?.running ?? false);
    return MyPageWebServiceStatus(
      enabled: enabled,
      running: running,
      baseUrl: running ? (status?.baseUrl ?? '') : '',
    );
  }

  static Future<File> _backupWithService() async {
    throw StateError('MyPagePortAdapter 需要由组合根注入 BackupService 的备份函数');
  }

  static bool _readEngineAvailability() => EngineStatusService.isAvailable;

  static bool _readDatabaseReadiness() => DatabaseStatusService.isReady;

  static String _readEngineVersion() => EngineStatusService.engineVersion;
}
