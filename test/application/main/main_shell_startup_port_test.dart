import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/main/main_shell_startup_port.dart';
import 'package:legado_flutter/application/startup/startup_task_runner.dart';

void main() {
  test('MainShell 启动任务保留三类后台报告和订阅待处理结果', () async {
    final report = StartupTaskReport(
      id: 'sources.load',
      status: StartupTaskStatus.succeeded,
      attempt: 1,
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026),
    );
    final tasks = MainShellStartupTasks(
      rssSources: Future.value(report),
      replaceRules: Future.value(report),
      sources: Future.value(report),
      ruleSubscriptions: Future.value(const []),
    );

    expect((await tasks.rssSources).status, StartupTaskStatus.succeeded);
    expect((await tasks.replaceRules).id, 'sources.load');
    expect((await tasks.sources).attempt, 1);
    expect(await tasks.ruleSubscriptions, isEmpty);
  });

  test('MainShell 书架摘要默认隐藏更新角标', () {
    const layout = MainShellBookshelfLayout();
    expect(layout.showWaitUpCount, isFalse);
  });
}
