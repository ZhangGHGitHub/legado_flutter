import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/features/reader/reader_markup.dart';
import 'package:legado_flutter/widgets/reader_inline_image.dart';

void main() {
  test('usehtml wrapper and formatting tags are not visible', () {
    const source = '<usehtml><p><b>第一行</b><br>第二行 &amp; 第三行</p><endhtml>';

    expect(ReaderMarkup.toPlainText(source), '第一行\n第二行 & 第三行');
  });

  test(
    'block html keeps paragraph boundaries and maps images to placeholders',
    () {
      const source =
          '<usehtml><div>上段</div><div>下段<img src="cover.jpg"></div>'
          '<hr><endhtml>';

      final document = ReaderMarkup.parse(source);
      expect(document.plainText, '上段\n下段${ReaderMarkup.imagePlaceholder}\n———');
      expect(document.images, hasLength(1));
      final image = document.images.single;
      expect(image.source, 'cover.jpg');
      expect(
        document.plainText.substring(image.start, image.end),
        ReaderMarkup.imagePlaceholder,
      );
      final span = document.spanForRange(
        const TextStyle(fontSize: 16),
        start: image.start,
        end: image.end,
      );
      final imageSpan = span.children!.single as WidgetSpan;
      final inlineImage = imageSpan.child as ReaderInlineImage;
      expect(inlineImage.source, 'cover.jpg');
      expect(inlineImage.width, greaterThan(0));
      expect(inlineImage.height, greaterThan(0));

      final sizedSpan = document.spanForRange(
        const TextStyle(fontSize: 16),
        start: image.start,
        end: image.end,
        imageSizes: const {'cover.jpg': Size(80, 40)},
        imageHeaders: const {'Cookie': 'reader=1'},
      );
      final sizedImage =
          (sizedSpan.children!.single as WidgetSpan).child as ReaderInlineImage;
      expect(sizedImage.width, 80);
      expect(sizedImage.height, 40);
      expect(sizedImage.headers, {'Cookie': 'reader=1'});
    },
  );

  test('ordinary text is unchanged without a usehtml wrapper', () {
    const source = '普通正文 <b>不是特殊 HTML</b>';

    expect(ReaderMarkup.toPlainText(source), source);
  });

  test('image URL options are separated from the request source', () {
    final document = ReaderMarkup.parse(
      "<usehtml><img src='https://example.com/a.png, "
      '{"style":"FULL","width":"50%","click":"https://example.com/open"}'
      "'><endhtml>",
    );

    final image = document.images.single;
    expect(image.source, 'https://example.com/a.png');
    expect(image.style, 'FULL');
    expect(image.width, '50%');
    expect(image.click, 'https://example.com/open');

    final recognizers = <GestureRecognizer>[];
    String? opened;
    final span = document.spanForRange(
      const TextStyle(fontSize: 16),
      start: image.start,
      end: image.end,
      onLink: (url) => opened = url,
      recognizers: recognizers,
    );
    final inlineImage =
        (span.children!.single as WidgetSpan).child as ReaderInlineImage;
    inlineImage.onTap!();
    expect(opened, 'https://example.com/open');
    for (final recognizer in recognizers) {
      recognizer.dispose();
    }
  });

  test('audio tags keep fallback text without exposing media markup', () {
    final document = ReaderMarkup.parse(
      '<usehtml>前<audio src="https://example.com/a.mp3">备用文本</audio>后<endhtml>',
    );

    expect(document.plainText, '前备用文本后');
    expect(document.images, isEmpty);
    expect(document.plainText, isNot(contains('audio')));
  });

  test('usehtml formatting becomes span styles', () {
    final document = ReaderMarkup.parse(
      '<usehtml><b>粗</b><i>斜</i><u>下</u>'
      '<font color="#ff0000">红</font><endhtml>',
    );

    expect(document.plainText, '粗斜下红');
    expect(document.runs[0].style?.fontWeight, FontWeight.bold);
    expect(document.runs[1].style?.fontStyle, FontStyle.italic);
    expect(document.runs[2].style?.decoration, TextDecoration.underline);
    expect(document.runs[3].style?.color, const Color(0xffff0000));
  });

  test('anchor URL becomes a clickable span callback', () {
    final document = ReaderMarkup.parse(
      '<usehtml><a href="https://example.com/read">打开</a><endhtml>',
    );
    final recognizers = <GestureRecognizer>[];
    String? opened;
    final span = document.spanForRange(
      const TextStyle(fontSize: 16),
      onLink: (url) => opened = url,
      recognizers: recognizers,
    );
    final child = span.children!.single as TextSpan;

    expect(document.runs.single.link, 'https://example.com/read');
    expect(child.recognizer, isA<TapGestureRecognizer>());
    (child.recognizer! as TapGestureRecognizer).onTap!();
    expect(opened, 'https://example.com/read');
    for (final recognizer in recognizers) {
      recognizer.dispose();
    }
  });
}
