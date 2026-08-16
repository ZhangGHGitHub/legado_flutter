import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/platform/platform_crash_metadata_loader.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads app and platform metadata without requiring the engine',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'Legado Flutter',
        packageName: 'io.legado.flutter',
        version: '2.3.4',
        buildNumber: '5',
        buildSignature: '',
      );

      final metadata = await const PlatformCrashMetadataLoader().call();
      expect(metadata.appVersion, '2.3.4+5');
      expect(metadata.platform, isNotEmpty);
      expect(metadata.platformVersion, isNotEmpty);
      expect(metadata.engineVersion, 'unavailable');
    },
  );
}
