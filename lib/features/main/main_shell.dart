import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/crash/crash_report.dart';
import '../../application/main/main_shell_startup_port.dart';
import '../../application/main/privacy_consent_port.dart';
import '../../application/startup/startup_task_runner.dart';
import '../../application/bookshelf/bookshelf_display_state_port.dart';
import '../../config/app_config.dart';
import '../../domain/source_subscription/rule_sub.dart';
import '../../theme/legado_chrome.dart';
import '../../widgets/legado_bottom_nav.dart';
import '../bookshelf/bookshelf_page.dart';
import '../explore/explore_tab_page.dart';
import '../../features/my/my_page.dart';
import '../../features/rss/rss_tab_page.dart';
import '../sources/rule_sub_page.dart';
import 'crash_recovery_prompt.dart';

/// 主框架 — 对齐 Jingshiro [MainActivity](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/MainActivity.kt)
///
/// 页面槽位固定：0=书架 1=发现 2=订阅 3=我的；底栏按 [AppConfig] 动态显隐。
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.pendingCrashReport,
    this.onCrashReportPresented,
    this.startupPort,
    this.displayStatePort,
  });

  final CrashReport? pendingCrashReport;
  final Future<void> Function()? onCrashReportPresented;
  final MainShellStartupPort? startupPort;
  final BookshelfDisplayStatePort? displayStatePort;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// 固定槽位索引（与 IndexedStack 子项一致）
  int _pageIndex = 0;
  bool _initialized = false;
  late final BookshelfDisplayStatePort _displayStatePort;
  int _lastBookshelfTapMs = 0;
  int _lastExploreTapMs = 0;
  DateTime? _lastBackPress;
  late final MainShellStartupPort _startupPort;
  late final PrivacyConsentPort _privacyPort;
  MainShellBookshelfLayout? _bookshelfLayout;

  final _bookshelfScrollController = ScrollController();
  final _bookshelfKey = GlobalKey<BookshelfPageState>();
  final _exploreKey = GlobalKey<ExploreTabPageState>();

  static const _exitInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _startupPort = widget.startupPort ?? context.read<MainShellStartupPort>();
    _privacyPort = context.read<PrivacyConsentPort>();
    _displayStatePort =
        widget.displayStatePort ??
        Provider.of<BookshelfDisplayStatePort?>(context, listen: false) ??
        const EmptyBookshelfDisplayStatePort();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initProviders());
  }

  @override
  void dispose() {
    _bookshelfScrollController.dispose();
    super.dispose();
  }

  Future<void> _initProviders() async {
    final runner = context.read<StartupTaskRunner>();

    await AppConfig.instance.load();
    if (!mounted) return;
    _bookshelfLayout = await _startupPort.loadBookshelfLayout();
    if (!mounted) return;

    final startup = _startupPort.startStartupTasks(runner: runner);
    unawaited(_showRuleSubscriptionImports(startup.ruleSubscriptions));
    for (final task in [
      startup.rssSources,
      startup.replaceRules,
      startup.sources,
    ]) {
      unawaited(
        task.then((_) {
          if (mounted) setState(() {});
        }),
      );
    }

    final defaultHome = AppConfig.instance.defaultHomePage;
    final homeIndex = switch (defaultHome) {
      'explore' => 1,
      'rss' => 2,
      'mine' => 3,
      _ => 0,
    };
    // 校验默认首页是否可见；隐藏 Tab 回退到第一个可见槽（通常 0=书架）
    final slots = _visiblePageSlots(AppConfig.instance);
    final validatedIndex = slots.contains(homeIndex) ? homeIndex : slots.first;

    if (mounted) {
      if (validatedIndex != 0) {
        setState(() => _pageIndex = validatedIndex);
      }
      setState(() => _initialized = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showStartupPrompts(),
      );
    }
  }

  Future<void> _showRuleSubscriptionImports(
    Future<List<RuleSub>> pending,
  ) async {
    try {
      final needUi = await pending;
      if (!mounted || needUi.isEmpty) return;
      for (final sub in needUi) {
        if (!mounted) return;
        await RuleSubPage.openImport(context, sub);
      }
    } catch (e) {
      debugPrint('ruleSubsUp failed: $e');
    }
  }

  Future<void> _showStartupPrompts() async {
    await _maybeShowPrivacy();
    if (!mounted) return;
    final report = widget.pendingCrashReport;
    if (report == null) return;
    await widget.onCrashReportPresented?.call();
    if (!mounted) return;
    await showCrashRecoveryPrompt(context, report);
  }

  Future<void> _maybeShowPrivacy() async {
    var accepted = false;
    try {
      accepted = await _privacyPort.isAccepted();
    } catch (_) {
      accepted = false;
    }
    if (accepted) return;
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
              try {
                await _privacyPort.saveAccepted();
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }

  /// 当前可见底栏对应的页面槽位（0/1/2/3）
  List<int> _visiblePageSlots(AppConfig cfg) {
    return [0, if (cfg.showDiscovery) 1, if (cfg.showRSS) 2, 3];
  }

  void _onDestinationSelected(int destIndex, List<int> slots) {
    if (destIndex < 0 || destIndex >= slots.length) return;
    final pageIndex = slots[destIndex];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (pageIndex == _pageIndex) {
      if (pageIndex == 0 && now - _lastBookshelfTapMs < 300) {
        _scrollBookshelfToTop();
      }
      if (pageIndex == 1 && now - _lastExploreTapMs < 300) {
        _exploreKey.currentState?.compressExplore();
      }
      if (pageIndex == 0) _lastBookshelfTapMs = now;
      if (pageIndex == 1) _lastExploreTapMs = now;
      return;
    }
    if (pageIndex == 0) {
      _lastBookshelfTapMs = now;
      _bookshelfKey.currentState?.reloadLayout();
    }
    if (pageIndex == 1) _lastExploreTapMs = now;
    setState(() => _pageIndex = pageIndex);
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
    if (_pageIndex != 0) {
      setState(() => _pageIndex = 0);
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

  static LegadoBottomNavItem _destination(
    int slot, {
    int shelfUpdateBadge = 0,
  }) {
    Widget? badge;
    if (shelfUpdateBadge > 0 && slot == 0) {
      final label = shelfUpdateBadge > 99 ? '99+' : '$shelfUpdateBadge';
      badge = Badge(label: Text(label));
    }

    return switch (slot) {
      0 => LegadoBottomNavItem(
        // 实心 library_books 字形偏左，选中只变色保持居中观感
        icon: Icons.library_books_outlined,
        selectedIcon: Icons.library_books_outlined,
        label: '书架',
        badge: badge,
      ),
      1 => const LegadoBottomNavItem(
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        label: '发现',
      ),
      2 => const LegadoBottomNavItem(
        icon: Icons.rss_feed_outlined,
        selectedIcon: Icons.rss_feed,
        label: '订阅',
      ),
      _ => const LegadoBottomNavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: '我的',
      ),
    };
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
        onConfigChanged: (_) {
          if (mounted) setState(() {});
        },
      ),
      ExploreTabPage(key: _exploreKey),
      const RssTabPage(),
      const MyPage(),
    ];

    return ListenableBuilder(
      listenable: AppConfig.instance,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: _displayStatePort,
          builder: (context, _) {
            final slots = _visiblePageSlots(AppConfig.instance);
            var pageIndex = _pageIndex;
            if (!slots.contains(pageIndex)) {
              pageIndex = 0;
              if (_pageIndex != 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !slots.contains(_pageIndex)) {
                    setState(() => _pageIndex = 0);
                  }
                });
              }
            }
            final selectedDest = slots
                .indexOf(pageIndex)
                .clamp(0, slots.length - 1);
            final shelfBadge = (_bookshelfLayout?.showWaitUpCount ?? false)
                ? _displayStatePort.shelfUpdateActiveCount
                : 0;

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                if (await _onWillPop()) {
                  await SystemNavigator.pop();
                }
              },
              child: Scaffold(
                body: IndexedStack(index: pageIndex, children: pages),
                bottomNavigationBar: LegadoBottomNav(
                  selectedIndex: selectedDest,
                  height: LegadoChrome.navigationBarHeightOf(context),
                  onDestinationSelected: (i) =>
                      _onDestinationSelected(i, slots),
                  destinations: [
                    for (final s in slots)
                      _destination(s, shelfUpdateBadge: shelfBadge),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
