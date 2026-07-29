import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../../bridge/legado_engine_bridge.dart';
import '../../domain/crash/crash_report.dart';

class PlatformCrashMetadataLoader {
  const PlatformCrashMetadataLoader();

  Future<CrashRuntimeMetadata> call() async {
    var appVersion = 'unknown';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.buildNumber.isEmpty
          ? packageInfo.version
          : '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {}
    var engineVersion = 'unavailable';
    if (LegadoEngineBridge.isAvailable) {
      try {
        engineVersion = LegadoEngineBridge.engineVersion();
      } catch (_) {}
    }
    return CrashRuntimeMetadata(
      platform: Platform.operatingSystem,
      platformVersion: Platform.operatingSystemVersion,
      appVersion: appVersion,
      engineVersion: engineVersion,
    );
  }
}
