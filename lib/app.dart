import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/main/main_shell.dart';
import 'pages/my/my_page.dart';
import 'pages/search/search_page.dart';
import 'pages/sources/sources_page.dart';
import 'theme/app_theme.dart';

/// App 根组件 — 主题 + 路由
class LegadoApp extends StatelessWidget {
  const LegadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeModeController>();

    return MaterialApp(
      title: 'Legado Flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeCtrl.materialThemeMode,
      home: const MainShell(),
      routes: {
        '/search': (context) => const SearchPage(),
        '/sources': (context) => const SourcesPage(),
        '/settings': (context) => const MyPage(),
      },
    );
  }
}
