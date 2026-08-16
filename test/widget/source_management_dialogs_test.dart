import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/widgets/import_book_source_dialog.dart';
import 'package:legado_flutter/widgets/source_group_manage_dialog.dart';

import '../features/sources/source_test_host.dart';

void main() {
  testWidgets('分组管理支持添加、重命名和删除并同步书源标签', (tester) async {
    final source = const BookSource(
      bookSourceUrl: 'https://source.example/group',
      bookSourceName: '分组源',
      bookSourceGroup: '旧分组',
    );
    final host = SourceTestHost(initialSources: [source]);
    await host.load();

    await tester.pumpWidget(
      host.wrap(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSourceGroupManageDialog(context),
              child: const Text('打开分组管理'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开分组管理'));
    await tester.pumpAndSettle();
    expect(find.text('旧分组'), findsOneWidget);

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '新分组');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(host.controller.sources.single.bookSourceGroup, '新分组');
    expect(find.text('新分组'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '独立分组');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(host.groups.names, contains('独立分组'));

    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(host.groups.names, isNot(contains('独立分组')));

    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(host.controller.sources.single.bookSourceGroup, isEmpty);
    expect(host.groups.names, isEmpty);
  });

  testWidgets('导入预览按新增、更新、相同分类并只写入勾选项', (tester) async {
    final existing = const BookSource(
      bookSourceUrl: 'https://source.example/existing',
      bookSourceName: '旧名称',
      lastUpdateTime: 10,
    );
    final update = existing.copyWith(bookSourceName: '新名称', lastUpdateTime: 20);
    final newSource = const BookSource(
      bookSourceUrl: 'https://source.example/new',
      bookSourceName: '新增源',
    );
    final host = SourceTestHost(initialSources: [existing]);
    await host.load();

    await tester.pumpWidget(
      host.wrap(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ImportBookSourceDialog(
                  candidates: [newSource, update, existing],
                  existingByUrl: {existing.bookSourceUrl: existing},
                ),
              ),
              child: const Text('打开导入预览'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开导入预览'));
    await tester.pumpAndSettle();
    expect(find.text('新增'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);
    expect(find.text('相同'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.tap(find.text('导入').last);
    await tester.pumpAndSettle();

    expect(host.controller.sources, hasLength(2));
    expect(
      host.controller.sources
          .singleWhere((source) => source.bookSourceUrl == update.bookSourceUrl)
          .bookSourceName,
      '新名称',
    );
    expect(
      host.controller.sources.any(
        (source) => source.bookSourceUrl == newSource.bookSourceUrl,
      ),
      isTrue,
    );
  });
}
