import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/settings/cache_management_port.dart';
import 'package:legado_flutter/application/settings/other_settings_port.dart';
import 'package:legado_flutter/domain/ports/network_engine_port.dart';
import 'package:legado_flutter/features/settings/other_settings_card.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/settings/cache_management_port_adapter.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:legado_flutter/services/cache_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    tempRoot = Directory.systemTemp.createTempSync('legado_other_settings_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') return tempRoot.path;
          return null;
        });
    SharedPreferences.setMockInitialValues({
      AppDataPrefs.dataDirKey: tempRoot.path,
    });
    await SharedPreferences.getInstance();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  testWidgets('OtherSettingsCard shows network cache and data sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<CacheManagementPort>.value(
        value: CacheManagementPortAdapter(_cacheService()),
        child: Provider<OtherSettingsPort>.value(
          value: const _FakeOtherSettingsPort(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: OtherSettingsCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      if (find.text('网络代理').evaluate().isNotEmpty) break;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    expect(find.text('网络代理'), findsOneWidget);
    expect(find.text('启用代理'), findsOneWidget);
    expect(find.text('保存网络设置'), findsOneWidget);
    expect(find.text('数据目录'), findsOneWidget);
    expect(find.text('保存数据目录'), findsOneWidget);
    expect(find.text('缓存管理'), findsOneWidget);
    expect(find.text('清书籍缓存'), findsOneWidget);
    expect(find.text('清 Cookie/JS'), findsOneWidget);
    expect(find.text('清本地备份'), findsOneWidget);
    expect(find.text('清理 HTTP TTS 缓存'), findsOneWidget);
    expect(find.text('一键清理'), findsOneWidget);
  });

  testWidgets('clears HTTP TTS cache and shows a success message', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<CacheManagementPort>.value(
        value: CacheManagementPortAdapter(_cacheService()),
        child: Provider<OtherSettingsPort>.value(
          value: const _FakeOtherSettingsPort(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: OtherSettingsCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      if (find.text('清理 HTTP TTS 缓存').evaluate().isNotEmpty) break;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }

    final clearButton = find.text('清理 HTTP TTS 缓存');
    await tester.ensureVisible(clearButton);
    await tester.tap(clearButton);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('HTTP TTS 缓存已清理'), findsOneWidget);
  });
}

CacheService _cacheService() => CacheService(
  contentCache: const FileChapterContentCache(),
  enginePort: const _FakeNetworkEnginePort(),
);

class _FakeNetworkEnginePort implements NetworkEnginePort {
  const _FakeNetworkEnginePort();

  @override
  bool get isAvailable => false;

  @override
  void clearEngineCache() {}

  @override
  void setNetworkConfig({
    required bool proxyEnabled,
    required String proxyType,
    required String proxyHost,
    required int proxyPort,
    required String proxyUsername,
    required String proxyPassword,
    required String dnsServers,
  }) {}
}

class _FakeOtherSettingsPort implements OtherSettingsPort {
  const _FakeOtherSettingsPort();

  @override
  bool get engineAvailable => false;

  @override
  Future<OtherNetworkConfig> loadNetwork() async => const OtherNetworkConfig();

  @override
  Future<void> saveNetwork(OtherNetworkConfig config) async {}

  @override
  Future<void> applyNetwork(OtherNetworkConfig config) async {}

  @override
  Future<String?> loadDataDir() async => null;

  @override
  Future<void> saveDataDir(String? path) async {}

  @override
  Future<void> clearHttpTtsCache() async {}
}
