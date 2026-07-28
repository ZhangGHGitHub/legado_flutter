import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/features/bookshelf/bookshelf_page.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('BookshelfPage shows empty state', (WidgetTester tester) async {
    final bookProvider = BookProvider(
      repository: BookDao(),
      contentCache: const FileChapterContentCache(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: bookProvider,
          child: const BookshelfPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('书架空空如也'), findsOneWidget);
  });
}
