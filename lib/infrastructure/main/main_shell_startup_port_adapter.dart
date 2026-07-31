import '../../application/main/main_shell_startup_port.dart';
import '../../application/startup/startup_task_runner.dart';
import '../../domain/ports/public_text_fetch_port.dart';
import '../../domain/source_subscription/rule_sub.dart';
import '../../providers/replace_provider.dart';
import '../../providers/rss_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/book_source_service.dart';
import '../../services/bookshelf_prefs.dart';
import '../../services/rule_sub_import_service.dart';

/// 将 MainShell 的启动编排收敛到现有服务和 Provider。
final class MainShellStartupPortAdapter implements MainShellStartupPort {
  const MainShellStartupPortAdapter({
    required BookSourceService sourceService,
    required SourceProvider sourceProvider,
    required RssProvider rssProvider,
    required ReplaceProvider replaceProvider,
    required PublicTextFetchPort fetchPort,
  }) : _sourceService = sourceService,
       _sourceProvider = sourceProvider,
       _rssProvider = rssProvider,
       _replaceProvider = replaceProvider,
       _fetchPort = fetchPort;

  final BookSourceService _sourceService;
  final SourceProvider _sourceProvider;
  final RssProvider _rssProvider;
  final ReplaceProvider _replaceProvider;
  final PublicTextFetchPort _fetchPort;

  @override
  Future<MainShellBookshelfLayout> loadBookshelfLayout() async {
    final config = await BookshelfPrefs.load();
    return MainShellBookshelfLayout(showWaitUpCount: config.showWaitUpCount);
  }

  @override
  MainShellStartupTasks startStartupTasks({required StartupTaskRunner runner}) {
    final rssSources = runner.run('rss.sources.load', _rssProvider.loadSources);
    final replaceRules = runner.run(
      'replace_rules.load',
      _replaceProvider.loadRules,
    );
    final builtInSources = runner.run(
      'sources.built_in.ensure',
      _sourceProvider.ensureBuiltInSources,
    );
    final sources = runner.run('sources.load', () async {
      final report = await builtInSources;
      if (report.status != StartupTaskStatus.succeeded) {
        throw StateError('内置书源任务未完成');
      }
      await _sourceProvider.loadSources();
      final error = _sourceProvider.loadError;
      if (error != null) throw StateError(error);
    });

    final pending = <RuleSub>[];
    final ruleUpdate = runner.run('rule_subscriptions.update', () async {
      final sourceReport = await sources;
      final rssReport = await rssSources;
      if (sourceReport.status != StartupTaskStatus.succeeded ||
          rssReport.status != StartupTaskStatus.succeeded) {
        throw StateError('书源或 RSS 加载任务未完成');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      pending.addAll(
        await RuleSubImportService.checkAutoUpdates(
          sourceService: _sourceService,
          sourceProvider: _sourceProvider,
          rssProvider: _rssProvider,
          replaceProvider: _replaceProvider,
          fetchPort: _fetchPort,
        ),
      );
    });

    return MainShellStartupTasks(
      rssSources: rssSources,
      replaceRules: replaceRules,
      sources: sources,
      ruleSubscriptions: ruleUpdate.then(
        (report) => report.status == StartupTaskStatus.succeeded
            ? List<RuleSub>.unmodifiable(pending)
            : const <RuleSub>[],
      ),
    );
  }
}
