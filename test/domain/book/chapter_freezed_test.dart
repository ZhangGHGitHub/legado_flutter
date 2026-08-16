import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/chapter.dart';

void main() {
  group('Chapter.idFor', () {
    test('uses UTF-16 code units for URL identity', () {
      expect(
        Chapter.idFor(bookId: 'book', url: 'A😀B', index: 4),
        'book_url_e8552801',
      );
    });

    test('falls back to the book and index when URL is empty', () {
      expect(Chapter.idFor(bookId: 'book', url: '', index: 4), 'book_ch_4');
    });
  });

  group('Chapter JSON', () {
    test('accepts idx and numeric strings without changing output shape', () {
      final chapter = Chapter.fromJson({
        'id': 'chapter-1',
        'bookId': 'book',
        'title': '第一章',
        'idx': '7',
        'url': null,
        'content': null,
      });

      expect(chapter.index, 7);
      expect(chapter.url, '');
      expect(chapter.toJson(), {
        'id': 'chapter-1',
        'bookId': 'book',
        'title': '第一章',
        'index': 7,
        'url': '',
        'isVolume': false,
        'isVip': false,
        'isPay': false,
        'tag': '',
        'baseUrl': '',
        'isDownloaded': false,
        'content': null,
      });
    });

    test('prefers index over the legacy idx alias', () {
      final chapter = Chapter.fromJson({
        'id': 'chapter-1',
        'bookId': 'book',
        'title': '第一章',
        'index': 2,
        'idx': 9,
        'url': '/1',
      });

      expect(chapter.index, 2);
    });
  });

  group('Chapter.mergeWithLocal', () {
    test('matches by URL and keeps local content/download state', () {
      final remote = Chapter(
        id: 'new-id',
        bookId: 'book',
        title: '远程标题',
        index: 3,
        url: '/chapter/3',
        isVolume: true,
        isVip: true,
        isPay: true,
        tag: 'remote',
        baseUrl: 'https://remote.example',
      );
      final local = Chapter(
        id: 'old-id',
        bookId: 'book',
        title: '旧标题',
        index: 1,
        url: '/chapter/3',
        isDownloaded: false,
        content: '本地正文',
      );

      final merged = Chapter.mergeWithLocal([remote], [local]).single;

      expect(merged.id, 'old-id');
      expect(merged.title, '远程标题');
      expect(merged.index, 3);
      expect(merged.isVolume, isTrue);
      expect(merged.isVip, isTrue);
      expect(merged.isPay, isTrue);
      expect(merged.tag, 'remote');
      expect(merged.baseUrl, 'https://remote.example');
      expect(merged.isDownloaded, isTrue);
      expect(merged.content, '本地正文');
    });

    test('matches by ID and preserves explicitly empty local content', () {
      final remote = Chapter(
        id: 'chapter-id',
        bookId: 'book',
        title: '远程标题',
        index: 2,
        url: '',
        content: '远程正文',
      );
      final local = Chapter(
        id: 'chapter-id',
        bookId: 'book',
        title: '本地标题',
        index: 1,
        url: '',
        content: '',
      );

      final merged = Chapter.mergeWithLocal([remote], [local]).single;

      expect(merged.title, '远程标题');
      expect(merged.index, 2);
      expect(merged.content, '');
      expect(merged.isDownloaded, isFalse);
    });
  });
}
