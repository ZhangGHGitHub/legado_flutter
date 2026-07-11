import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'bridge/legado_db_bridge.dart';
import 'bridge/legado_engine_bridge.dart';
import 'config/engine_config.dart';
import 'providers/book_provider.dart';
import 'providers/source_provider.dart';
import 'providers/replace_provider.dart';
import 'theme/app_theme.dart';

/// 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EngineConfig.load();
  await LegadoEngineBridge.tryInit();
  if (LegadoEngineBridge.isAvailable) {
    await LegadoDbBridge.init();
  }

  final themeController = ThemeModeController();
  await themeController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => ReplaceProvider()..loadRules()),
      ],
      child: const LegadoApp(),
    ),
  );
}
