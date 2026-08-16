import '../startup/startup_task_runner.dart';
import '../../domain/source_subscription/rule_sub.dart';

/// MainShell 首屏需要的书架显示摘要。
///
/// 书架页面仍负责自身完整配置；主框架只读取角标所需的字段，避免把
/// SharedPreferences 细节带入页面。
final class MainShellBookshelfLayout {
  const MainShellBookshelfLayout({this.showWaitUpCount = false});

  final bool showWaitUpCount;
}

/// MainShell 启动阶段的后台任务句柄。
final class MainShellStartupTasks {
  const MainShellStartupTasks({
    required this.rssSources,
    required this.replaceRules,
    required this.sources,
    required this.ruleSubscriptions,
  });

  final Future<StartupTaskReport> rssSources;
  final Future<StartupTaskReport> replaceRules;
  final Future<StartupTaskReport> sources;

  /// 规则订阅任务完成后需要打开导入 UI 的订阅。
  final Future<List<RuleSub>> ruleSubscriptions;
}

/// 主框架启动数据与任务编排边界。
abstract interface class MainShellStartupPort {
  Future<MainShellBookshelfLayout> loadBookshelfLayout();

  MainShellStartupTasks startStartupTasks({required StartupTaskRunner runner});
}
