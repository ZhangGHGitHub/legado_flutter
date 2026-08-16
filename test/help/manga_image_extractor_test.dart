import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/manga_image_extractor.dart';
import 'package:legado_flutter/services/manga_prefs.dart';

void main() {
  group('MangaImageExtractor', () {
    test('extracts img src and data-src', () {
      const html = '''
        <div>
          <img src="https://cdn.example/a.jpg" />
          <img data-src="https://cdn.example/b.png" src="data:image/gif;base64,xx" />
        </div>
      ''';
      expect(
        MangaImageExtractor.extract(html),
        [
          'https://cdn.example/a.jpg',
          'https://cdn.example/b.png',
        ],
      );
    });

    test('extracts markdown and bare urls', () {
      const text = '''
![p1](https://cdn.example/1.webp)
https://cdn.example/2.gif?x=1
''';
      expect(
        MangaImageExtractor.extract(text),
        [
          'https://cdn.example/1.webp',
          'https://cdn.example/2.gif?x=1',
        ],
      );
    });

    test('resolves relative urls against base', () {
      final urls = MangaImageExtractor.extract(
        '<img src="/img/3.jpg">',
        baseUrl: 'https://site.example/chapter/1.html',
      );
      expect(urls, ['https://site.example/img/3.jpg']);
    });

    test('looksLikeManga when images dominate', () {
      expect(
        MangaImageExtractor.looksLikeManga(
          '<img src="https://a.com/1.jpg"><img src="https://a.com/2.jpg">',
        ),
        isTrue,
      );
      expect(
        MangaImageExtractor.looksLikeManga('这是一整章很长的文字小说正文……' * 5),
        isFalse,
      );
    });
  });

  group('MangaPrefs', () {
    test('isImageSourceType recognizes legado type 2', () {
      expect(MangaPrefs.isImageSourceType('2'), isTrue);
      expect(MangaPrefs.isImageSourceType('image'), isTrue);
      expect(MangaPrefs.isImageSourceType('0'), isFalse);
      expect(MangaPrefs.isImageSourceType(null), isFalse);
    });

    test('direction cycles', () {
      expect(
        MangaReadDirection.vertical.next,
        MangaReadDirection.leftToRight,
      );
      expect(
        MangaReadDirection.rightToLeft.next,
        MangaReadDirection.vertical,
      );
    });
  });
}
