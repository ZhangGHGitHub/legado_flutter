import 'package:flutter/material.dart';
import 'pages/bookshelf/bookshelf_page.dart';
import 'pages/search/search_page.dart';
import 'pages/sources/sources_page.dart';
import 'pages/settings/settings_page.dart';

/// App 根组件 - 底部导航 + 主题
class LegadoApp extends StatelessWidget {
  const LegadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legado Flutter',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      themeMode: ThemeMode.system,
      home: const MainShell(),

      routes: {
        '/sources': (context) => const SourcesPage(),
        '/settings': (context) => const SettingsPage(),
        '/reader': (context) => const Scaffold(
          body: Center(child: Text('阅读器页面')),
        ),
      },
    );
  }
}

/// 主框架 - 底部导航栏
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BookshelfPage(),
    SearchPage(),
    SourcesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: '书架',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: '书源',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
