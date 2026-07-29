import 'dart:async';

import 'package:flutter/widgets.dart';

import 'application/crash/crash_log_service.dart';
import 'bootstrap/app_composition_root.dart';
import 'infrastructure/platform/global_crash_handler.dart';
import 'infrastructure/platform/platform_crash_metadata_loader.dart';
import 'infrastructure/preferences/shared_preferences_crash_report_store.dart';

export 'application/app_bootstrap.dart' show loadStartupBookProgress;

void main() {
  final crashLog = CrashLogService(
    store: const SharedPreferencesCrashReportStore(),
    metadataLoader: const PlatformCrashMetadataLoader().call,
  );
  final globalCrashHandler = GlobalCrashHandler(crashLog: crashLog);

  runZonedGuarded(() async {
    crashLog.updateStartupStage('Flutter 绑定初始化');
    WidgetsFlutterBinding.ensureInitialized();
    globalCrashHandler.install();

    // 整站关闭语义曾与阅读器正文空白并存，阅读器只允许局部管理语义树。
    await AppCompositionRoot.run(crashLog: crashLog);
  }, globalCrashHandler.handleZoneError);
}
