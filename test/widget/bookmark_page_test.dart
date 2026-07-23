import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/book/bookmark_page.dart';

void main() {
  testWidgets('BookmarkPage shows title and empty hint', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BookmarkPage()));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      if (find.text('暂无书签').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('书签与想法'), findsOneWidget);
    expect(find.byTooltip('上传书签到 WebDAV'), findsOneWidget);
    expect(find.byTooltip('从 WebDAV 合并书签'), findsOneWidget);
    // 默认 Tab 为「书签」；想法空态在第二 Tab
    expect(find.text('暂无书签'), findsOneWidget);

    await tester.tap(find.text('想法'));
    await tester.pumpAndSettle();

    expect(find.text('暂无想法'), findsOneWidget);
    expect(find.textContaining('写想法'), findsOneWidget);
  });
}
