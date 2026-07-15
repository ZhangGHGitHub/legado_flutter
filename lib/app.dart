import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/main/main_shell.dart';
import 'pages/my/my_page.dart';
import 'pages/search/search_page.dart';
import 'pages/sources/sources_page.dart';
import 'pages/welcome/welcome_page.dart';
import 'theme/app_theme.dart';

/// App 根组件 — MD3 主题 + Dynamic Color + 路由
class LegadoApp extends StatelessWidget {
  const LegadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeModeController>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'Legado Flutter',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(
            preset: themeCtrl.preset,
            customColors: themeCtrl.customColors,
            dynamicLight: lightDynamic,
            dynamicDark: darkDynamic,
          ),
          darkTheme: AppTheme.dark(
            preset: themeCtrl.preset,
            customColors: themeCtrl.customColors,
            dynamicLight: lightDynamic,
            dynamicDark: darkDynamic,
          ),
          themeMode: themeCtrl.materialThemeMode,
          home: const _StartupHome(),
          routes: {
            '/search': (context) => const SearchPage(),
            '/sources': (context) => const SourcesPage(),
            '/settings': (context) => const MyPage(),
          },
        );
      },
    );
  }
}

/// 冷启 → [WelcomePage] 闪屏（对齐 WelcomeActivity）→ [MainShell]。
/// 隐私协议 Dialog 由 MainShell 首次弹出（对齐 Jingshiro 主路径）。
class _StartupHome extends StatefulWidget {
  const _StartupHome();

  @override
  State<_StartupHome> createState() => _StartupHomeState();
}

class _StartupHomeState extends State<_StartupHome> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return WelcomePage(
        onFinished: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }
    return const MainShell();
  }
}
