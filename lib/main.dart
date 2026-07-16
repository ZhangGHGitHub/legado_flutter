import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'bridge/legado_db_bridge.dart';
import 'bridge/legado_engine_bridge.dart';
import 'config/app_config.dart';
import 'config/engine_config.dart';
import 'services/web_api_service.dart';
import 'services/network_prefs.dart';
import 'providers/book_provider.dart';
import 'providers/source_provider.dart';
import 'providers/replace_provider.dart';
import 'providers/rss_provider.dart';
import 'theme/app_theme.dart';

/// 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注意：不要在此调用 setSemanticsTreeEnabled(false) / 整站 ExcludeSemantics。
  // 整站关闭语义曾与阅读器正文空白并存；AXTree 压制改到阅读器页内（见 reader_page）。

  await EngineConfig.load();
  await AppConfig.instance.load();
  await LegadoEngineBridge.tryInit();
  if (LegadoEngineBridge.isAvailable) {
    await LegadoDbBridge.init();
    await NetworkPrefs.restoreToEngine();
    await WebApiService.restoreIfEnabled();
  }

  final themeController = ThemeModeController();
  await themeController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: AppConfig.instance),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => ReplaceProvider()..loadRules()),
        ChangeNotifierProvider(create: (_) => RssProvider()..loadSources()),
      ],
      child: const LegadoApp(),
    ),
  );
}
