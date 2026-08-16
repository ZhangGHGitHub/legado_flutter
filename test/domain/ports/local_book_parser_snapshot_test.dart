import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/local_book_parser_port.dart';

void main() {
  test('chapter snapshot preserves parsed title and content', () {
    const snapshot = LocalBookChapterSnapshot(title: '第一章', content: '正文内容');

    expect(snapshot.title, '第一章');
    expect(snapshot.content, '正文内容');
    expect(
      snapshot,
      const LocalBookChapterSnapshot(title: '第一章', content: '正文内容'),
    );
  });

  test(
    'epub snapshot preserves chapter order and immutable list semantics',
    () {
      final chapters = [
        const LocalBookChapterSnapshot(title: '序章', content: '序章正文'),
        const LocalBookChapterSnapshot(title: '第一章', content: '第一章正文'),
      ];
      final snapshot = LocalBookEpubSnapshot(
        title: '测试书',
        author: '测试作者',
        chapters: chapters,
      );

      expect(snapshot.title, '测试书');
      expect(snapshot.author, '测试作者');
      expect(snapshot.chapters, chapters);
      expect(snapshot.chapters.map((chapter) => chapter.title), ['序章', '第一章']);
      expect(
        () => snapshot.chapters.add(
          const LocalBookChapterSnapshot(title: '尾章', content: '尾章正文'),
        ),
        throwsUnsupportedError,
      );
    },
  );
}
