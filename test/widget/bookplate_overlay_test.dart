import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/services/bookplate_service.dart';
import 'package:legado_flutter/widgets/bookplate_overlay.dart';

void main() {
  final book = Book(
    id: 'b1',
    name: '测试书籍',
    author: '作者甲',
    progress: 0.8,
  );

  const preview = BookplateData(
    bookName: '测试书籍',
    author: '作者甲',
    rating: 4,
    durationLabel: '1 小时',
    charsLabel: '1.2 万字',
    startDate: '2026-07-01',
    finishDate: null,
    chaptersRead: 8,
    totalChapters: 10,
    progress: 0.8,
  );

  testWidgets('BookplateOverlay header shows title and start date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookplateOverlay(
            book: book,
            currentChapterIndex: 7,
            totalChapters: 10,
            textColor: Colors.black87,
            isHeader: true,
            previewData: preview,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('测试书籍'), findsOneWidget);
    expect(find.text('作者甲'), findsOneWidget);
    expect(find.textContaining('开始 2026-07-01'), findsOneWidget);
  });

  testWidgets('BookplateOverlay footer shows duration and chapters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookplateOverlay(
            book: book,
            currentChapterIndex: 7,
            totalChapters: 10,
            textColor: Colors.black87,
            isHeader: false,
            previewData: preview,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('阅读 1 小时'), findsOneWidget);
    expect(find.textContaining('8/10 章'), findsOneWidget);
    expect(find.textContaining('进度 80%'), findsOneWidget);
  });
}
