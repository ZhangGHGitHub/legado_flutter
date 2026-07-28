import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/models/rss_source.dart';
import 'package:legado_flutter/features/rss/rss_source_edit_page.dart';
import 'package:legado_flutter/services/rss_source_edit_port.dart';

class _FakeRssSourceEditPort implements RssSourceEditPort {
  RssSource? saved;

  @override
  Future<void> save(RssSource source) async {
    saved = source;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editor saves through the injected boundary', (tester) async {
    final editor = _FakeRssSourceEditPort();
    await tester.pumpWidget(
      MaterialApp(home: RssSourceEditPage(editor: editor)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'https://example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Example RSS');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(editor.saved?.sourceUrl, 'https://example.com');
    expect(editor.saved?.sourceName, 'Example RSS');
  });
}
