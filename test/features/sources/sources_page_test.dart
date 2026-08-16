import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';
import 'package:legado_flutter/features/sources/sources_page.dart';
import 'package:legado_flutter/widgets/source_status_dot.dart';

import 'source_test_host.dart';

void main() {
  testWidgets('SourcesPage 批量启用通过 SourceNotifier 更新单一状态', (tester) async {
    final source = const BookSource(
      bookSourceUrl: 'https://source.example/batch',
      bookSourceName: '批量源',
      enabled: false,
    );
    final host = SourceTestHost(initialSources: [source]);
    await host.load();

    await tester.pumpWidget(host.wrap(const SourcesPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.byTooltip('更多').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('启用所选'));
    await tester.pumpAndSettle();

    expect(host.controller.sources.single.enabled, isTrue);
    expect(host.repository.sources.single.enabled, isTrue);
    expect(find.text('已启用 1 个书源'), findsOneWidget);
  });

  testWidgets('SourcesPage 显示已持久化的校验状态点', (tester) async {
    final source = const BookSource(
      bookSourceUrl: 'https://source.example/validation',
      bookSourceName: '状态源',
    );
    final result = const SourceValidationResult(
      searchOk: true,
      discoveryOk: true,
      tocOk: false,
      contentOk: true,
      searchTimeMs: 27,
    );
    final host = SourceTestHost(
      initialSources: [source],
      validationResults: {source.bookSourceUrl: result},
    );
    await host.load();

    await tester.pumpWidget(host.wrap(const SourcesPage()));
    await tester.pumpAndSettle();

    final dot = tester.widget<SourceStatusDot>(find.byType(SourceStatusDot));
    expect(dot.validation, result);
    expect(dot.validation?.pipelineOk, isFalse);
  });
}
