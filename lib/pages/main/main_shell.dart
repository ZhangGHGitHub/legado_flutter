import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database_helper.dart';
import '../../providers/book_provider.dart';
import '../../providers/rss_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/book_source_service.dart';
import '../bookshelf/bookshelf_page.dart';
import '../explore/explore_tab_page.dart';
import '../my/my_page.dart';
import '../rss/rss_tab_page.dart';

const _privacyAcceptedKey = 'legado_privacy_accepted';

/// 主框架 — 对齐 Jingshiro [MainActivity](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/MainActivity.kt)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _initialized = false;
  int _lastBookshelfTapMs = 0;
  int _lastExploreTapMs = 0;
  DateTime? _lastBackPress;

  final _bookshelfScrollController = ScrollController();
  final _bookshelfKey = GlobalKey<BookshelfPageState>();
  final _exploreKey = GlobalKey<ExploreTabPageState>();

  static const _exitInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initProviders());
  }

  @override
  void dispose() {
    _bookshelfScrollController.dispose();
    super.dispose();
  }

  Future<void> _initProviders() async {
    final db = DatabaseHelper();
    final bookProvider = context.read<BookProvider>();
    final sourceProvider = context.read<SourceProvider>();
    final rssProvider = context.read<RssProvider>();

    await bookProvider.loadBooks();
    await rssProvider.loadSources();

    var sources = await db.getBookSources();
    if (sources.isEmpty) {
      await db.insertBookSources(await BookSourceService.loadBuiltInSources());
      sources = await db.getBookSources();
    }
    await sourceProvider.loadSources();

    if (mounted) {
      setState(() => _initialized = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrivacy());
    }
  }

  Future<void> _maybeShowPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_privacyAcceptedKey) == true) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('隐私政策与用户协议'),
        content: const SingleChildScrollView(
          child: Text(
            '欢迎使用 Legado Flutter（对齐 Jingshiro/Legado 的 Flutter 复刻版）。\n\n'
            '• 本应用为本地阅读工具，书源规则由用户自行导入。\n'
            '• 搜索、发现、阅读等功能需访问网络，数据仅用于获取书籍内容。\n'
            '• 书架、书源、阅读进度等数据默认保存在本机。\n\n'
            '继续使用即表示您同意上述说明。',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('拒绝并退出'),
          ),
          FilledButton(
            onPressed: () async {
              await prefs.setBool(_privacyAcceptedKey, true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }

  void _onTabSelected(int index) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (index == _currentIndex) {
      if (index == 0 && now - _lastBookshelfTapMs < 300) {
        _scrollBookshelfToTop();
      }
      if (index == 1 && now - _lastExploreTapMs < 300) {
        _exploreKey.currentState?.compressExplore();
      }
      if (index == 0) _lastBookshelfTapMs = now;
      if (index == 1) _lastExploreTapMs = now;
      return;
    }
    if (index == 0) _lastBookshelfTapMs = now;
    if (index == 1) _lastExploreTapMs = now;
    if (index == 0) _bookshelfKey.currentState?.reloadLayout();
    setState(() => _currentIndex = index);
  }

  void _scrollBookshelfToTop() {
    if (_bookshelfScrollController.hasClients) {
      _bookshelfScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > _exitInterval) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次退出'),
          duration: _exitInterval,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      BookshelfPage(
        key: _bookshelfKey,
        scrollController: _bookshelfScrollController,
      ),
      ExploreTabPage(key: _exploreKey),
      const RssTabPage(),
      const MyPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: '书架',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: '发现',
            ),
            NavigationDestination(
              icon: Icon(Icons.subscriptions_outlined),
              selectedIcon: Icon(Icons.subscriptions),
              label: '订阅',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
