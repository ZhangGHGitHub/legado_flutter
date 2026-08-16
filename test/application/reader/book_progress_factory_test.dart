import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/book_progress_factory.dart';
import 'package:legado_flutter/domain/book/book.dart';

void main() {
  test('fromBook 保持阅读位置、书籍身份和注入时间', () {
    final book = Book(
      id: 'book-id',
      name: '测试书',
      author: '作者',
      currentChapter: '本地章节',
    );
    final now = DateTime.fromMillisecondsSinceEpoch(123456789);

    final progress = BookProgressFactory.fromBook(
      book,
      durChapterIndex: 7,
      durChapterPos: 19,
      durChapterTitle: '云端章节',
      now: () => now,
    );

    expect(progress.name, '测试书');
    expect(progress.author, '作者');
    expect(progress.durChapterIndex, 7);
    expect(progress.durChapterPos, 19);
    expect(progress.durChapterTime, 123456789);
    expect(progress.durChapterTitle, '云端章节');
  });

  test('fromBook 未指定章节标题时沿用当前章节', () {
    final book = Book(
      id: 'book-id',
      name: '测试书',
      author: '作者',
      currentChapter: '当前章节',
    );

    final progress = BookProgressFactory.fromBook(
      book,
      durChapterIndex: 0,
      durChapterPos: 0,
      now: () => DateTime.fromMillisecondsSinceEpoch(1),
    );

    expect(progress.durChapterTitle, '当前章节');
  });
}
