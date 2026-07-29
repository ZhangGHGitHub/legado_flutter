import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/main/main_shell.dart';
import 'features/my/my_page.dart';
import 'features/search/search_page.dart';
import 'features/sources/sources_page.dart';
import 'features/main/welcome_page.dart';
import 'theme/app_theme.dart';
import 'theme/legado_chrome.dart';

/// App 根组件 — MD3 主题 + Dynamic Color + 路由
class LegadoApp extends StatelessWidget {
  const LegadoApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeModeController>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          navigatorKey: navigatorKey,
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
          // 按 MediaQuery 断点覆盖顶/底栏高度（DPI 自动缩放，非屏高百分比）
          builder: (context, child) {
            final themed = LegadoChrome.applyTo(context, Theme.of(context));
            return Theme(data: themed, child: child ?? const SizedBox.shrink());
          },
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
