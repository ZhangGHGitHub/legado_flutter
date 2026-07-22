import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import '../../widgets/reader_inline_image.dart';
import '../../services/reader_image_cache.dart';

class ReaderMarkupRun {
  final int start;
  final int end;
  final String text;
  final TextStyle? style;
  final String? link;

  const ReaderMarkupRun({
    required this.start,
    required this.end,
    required this.text,
    this.style,
    this.link,
  });
}

class ReaderMarkupImage {
  final int start;
  final int end;
  final String source;
  final String? link;
  final String? style;
  final String? width;
  final String? click;

  String get key => '$start:$end';

  const ReaderMarkupImage({
    required this.start,
    required this.end,
    required this.source,
    this.link,
    this.style,
    this.width,
    this.click,
  });
}

class ReaderImageUrlOptions {
  final String source;
  final String? style;
  final String? width;
  final String? click;

  const ReaderImageUrlOptions({
    required this.source,
    this.style,
    this.width,
    this.click,
  });

  static final _optionsSeparator = RegExp(r'\s*,\s*(?=\{)');

  static ReaderImageUrlOptions parse(String raw) {
    final match = _optionsSeparator.firstMatch(raw);
    if (match == null) return ReaderImageUrlOptions(source: raw);
    try {
      final decoded = jsonDecode(raw.substring(match.end));
      if (decoded is! Map) return ReaderImageUrlOptions(source: raw);
      String? value(String key) {
        final item = decoded[key];
        return item?.toString();
      }

      return ReaderImageUrlOptions(
        source: raw.substring(0, match.start),
        style: value('style'),
        width: value('width'),
        click: value('click'),
      );
    } on FormatException {
      return ReaderImageUrlOptions(source: raw);
    }
  }
}

/// Visible text and style runs produced from one reader markup string.
class ReaderMarkupDocument {
  final String plainText;
  final List<ReaderMarkupRun> runs;
  final List<ReaderMarkupImage> images;

  const ReaderMarkupDocument({
    required this.plainText,
    required this.runs,
    this.images = const [],
  });

  TextSpan spanForRange(
    TextStyle baseStyle, {
    int start = 0,
    int? end,
    void Function(String url)? onLink,
    List<GestureRecognizer>? recognizers,
    ReaderImageCache? imageCache,
    Map<String, Size>? imageSizes,
    Map<String, String> imageHeaders = const {},
  }) {
    final rangeStart = start.clamp(0, plainText.length);
    final rangeEnd = (end ?? plainText.length).clamp(
      rangeStart,
      plainText.length,
    );
    final children = <InlineSpan>[];
    for (final run in runs) {
      final childStart = run.start.clamp(rangeStart, rangeEnd);
      final childEnd = run.end.clamp(rangeStart, rangeEnd);
      if (childStart >= childEnd) continue;
      final offset = childStart - run.start;
      ReaderMarkupImage? image;
      if (childStart == run.start && childEnd == run.end) {
        for (final candidate in images) {
          if (candidate.start == run.start && candidate.end == run.end) {
            image = candidate;
            break;
          }
        }
      }
      if (image != null) {
        final fontSize = run.style?.fontSize ?? baseStyle.fontSize ?? 14;
        final lineHeight =
            fontSize * (run.style?.height ?? baseStyle.height ?? 1.2);
        final imageSize = imageSizes?[image.key] ?? imageSizes?[image.source];
        final placeholder = SizedBox(
          width: imageSize?.width ?? fontSize * 1.56,
          height: imageSize?.height ?? lineHeight,
        );
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ReaderInlineImage(
              source: image.source,
              width: placeholder.width!,
              height: placeholder.height!,
              headers: imageHeaders,
              imageCache: imageCache,
              onTap: (image.click ?? image.link) != null && onLink != null
                  ? () => onLink(image!.click ?? image.link!)
                  : null,
            ),
          ),
        );
        continue;
      }
      TapGestureRecognizer? recognizer;
      if (run.link != null && onLink != null) {
        recognizer = TapGestureRecognizer()..onTap = () => onLink(run.link!);
        recognizers?.add(recognizer);
      }
      children.add(
        TextSpan(
          text: run.text.substring(offset, offset + childEnd - childStart),
          style: run.style,
          recognizer: recognizer,
        ),
      );
    }
    return TextSpan(style: baseStyle, children: children);
  }
}

/// Converts Legado's marked HTML fragments to visible reader text and spans.
abstract final class ReaderMarkup {
  /// One visible character position reserved for an inline image.
  static const imagePlaceholder = '\uFFFC';

  static final _useHtml = RegExp(
    r'<usehtml\b[^>]*>([\s\S]*?)<(?:endhtml|/usehtml)\s*>',
    caseSensitive: false,
  );
  static final _hardPageBreak = RegExp(
    r'^\s*\[newpage\]\s*(?:\n|$)',
    multiLine: true,
  );

  static String toPlainText(
    String source, {
    bool removeHardPageBreaks = false,
  }) {
    return parse(source, removeHardPageBreaks: removeHardPageBreaks).plainText;
  }

  static ReaderMarkupDocument parse(
    String source, {
    bool removeHardPageBreaks = false,
  }) {
    if (removeHardPageBreaks) {
      source = source.replaceAll(_hardPageBreak, '');
    }
    final plain = StringBuffer();
    final runs = <ReaderMarkupRun>[];
    final images = <ReaderMarkupImage>[];
    var cursor = 0;

    void appendRun(String text, TextStyle? style, String? link) {
      if (text.isEmpty) return;
      final start = plain.length;
      plain.write(text);
      runs.add(
        ReaderMarkupRun(
          start: start,
          end: start + text.length,
          text: text,
          style: style,
          link: link,
        ),
      );
    }

    for (final match in _useHtml.allMatches(source)) {
      appendRun(source.substring(cursor, match.start), null, null);
      final fragment = _parseHtmlFragment(match.group(1) ?? '');
      final offset = plain.length;
      for (final run in fragment.runs) {
        appendRun(run.text, run.style, run.link);
      }
      for (final image in fragment.images) {
        images.add(
          ReaderMarkupImage(
            start: offset + image.start,
            end: offset + image.end,
            source: image.source,
            link: image.link,
            style: image.style,
            width: image.width,
            click: image.click,
          ),
        );
      }
      cursor = match.end;
    }
    appendRun(source.substring(cursor), null, null);

    return ReaderMarkupDocument(
      plainText: plain.toString(),
      runs: runs,
      images: images,
    );
  }

  static ReaderMarkupDocument _parseHtmlFragment(String fragment) {
    final document = html_parser.parseFragment(fragment);
    final plain = StringBuffer();
    final runs = <ReaderMarkupRun>[];
    final images = <ReaderMarkupImage>[];

    void appendLocal(String text, TextStyle? style, String? link) {
      if (text.isEmpty) return;
      final start = plain.length;
      plain.write(text);
      runs.add(
        ReaderMarkupRun(
          start: start,
          end: start + text.length,
          text: text,
          style: style,
          link: link,
        ),
      );
    }

    for (final node in document.nodes) {
      _appendNode(node, null, null, appendLocal, plain, runs, images);
    }
    var start = 0;
    var end = plain.length;
    final value = plain.toString();
    while (start < end && value[start] == '\n') {
      start++;
    }
    while (end > start && value[end - 1] == '\n') {
      end--;
    }
    final trimmedRuns = <ReaderMarkupRun>[];
    for (final run in runs) {
      final runStart = run.start.clamp(start, end);
      final runEnd = run.end.clamp(start, end);
      if (runStart < runEnd) {
        trimmedRuns.add(
          ReaderMarkupRun(
            start: runStart - start,
            end: runEnd - start,
            text: run.text.substring(runStart - run.start, runEnd - run.start),
            style: run.style,
            link: run.link,
          ),
        );
      }
    }
    final trimmedImages = <ReaderMarkupImage>[];
    for (final image in images) {
      final imageStart = image.start.clamp(start, end);
      final imageEnd = image.end.clamp(start, end);
      if (imageStart < imageEnd) {
        trimmedImages.add(
          ReaderMarkupImage(
            start: imageStart - start,
            end: imageEnd - start,
            source: image.source,
            link: image.link,
            style: image.style,
            width: image.width,
            click: image.click,
          ),
        );
      }
    }
    return ReaderMarkupDocument(
      plainText: value.substring(start, end),
      runs: trimmedRuns,
      images: trimmedImages,
    );
  }

  static void _appendNode(
    dom.Node node,
    TextStyle? inherited,
    String? inheritedLink,
    void Function(String text, TextStyle? style, String? link) appendRun,
    StringBuffer plain,
    List<ReaderMarkupRun> runs,
    List<ReaderMarkupImage> images,
  ) {
    if (node is dom.Text) {
      appendRun(node.data, inherited, inheritedLink);
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName?.toLowerCase();
    if (tag == 'audio') {
      // Android HtmlCompat ignores the media element itself but keeps fallback text.
      for (final child in node.nodes) {
        _appendNode(
          child,
          inherited,
          inheritedLink,
          appendRun,
          plain,
          runs,
          images,
        );
      }
      return;
    }
    if (tag == 'img') {
      final rawSource = node.attributes['src'];
      if (rawSource == null || rawSource.isEmpty) return;
      final options = ReaderImageUrlOptions.parse(rawSource);
      final start = plain.length;
      appendRun(imagePlaceholder, inherited, inheritedLink);
      images.add(
        ReaderMarkupImage(
          start: start,
          end: start + imagePlaceholder.length,
          source: options.source,
          link: inheritedLink,
          style: options.style,
          width: options.width,
          click: options.click,
        ),
      );
      return;
    }
    if (tag == 'br') {
      appendRun('\n', inherited, inheritedLink);
      return;
    }
    if (tag == 'hr') {
      appendRun('———', inherited, inheritedLink);
      return;
    }

    final nextStyle = _styleForElement(node, inherited);
    final nextLink = tag == 'a'
        ? node.attributes['href'] ?? inheritedLink
        : inheritedLink;
    final isBlock = const {
      'address',
      'article',
      'blockquote',
      'div',
      'li',
      'p',
      'pre',
      'section',
      'tr',
    }.contains(tag);
    if (isBlock && plain.isNotEmpty && !plain.toString().endsWith('\n')) {
      appendRun('\n', inherited, inheritedLink);
    }
    for (final child in node.nodes) {
      _appendNode(child, nextStyle, nextLink, appendRun, plain, runs, images);
    }
    if (isBlock && !plain.toString().endsWith('\n')) {
      appendRun('\n', inherited, inheritedLink);
    }
  }

  static TextStyle? _styleForElement(
    dom.Element element,
    TextStyle? inherited,
  ) {
    final tag = element.localName?.toLowerCase();
    var style = inherited;
    if (tag == 'b' || tag == 'strong') {
      style = (style ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.bold,
      );
    } else if (tag == 'i' || tag == 'em') {
      style = (style ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
      );
    } else if (tag == 'u') {
      style = (style ?? const TextStyle()).copyWith(
        decoration: TextDecoration.underline,
      );
    } else if (tag == 'a') {
      style = (style ?? const TextStyle()).copyWith(
        color: const Color(0xff1565c0),
        decoration: TextDecoration.underline,
      );
    }

    final declaration = element.attributes['style'];
    if (declaration != null) {
      final properties = <String, String>{};
      for (final item in declaration.split(';')) {
        final separator = item.indexOf(':');
        if (separator <= 0) continue;
        properties[item.substring(0, separator).trim().toLowerCase()] = item
            .substring(separator + 1)
            .trim();
      }
      final weight = properties['font-weight'];
      final fontStyle = properties['font-style'];
      final decoration = properties['text-decoration'];
      final color = _parseColor(properties['color']);
      style = (style ?? const TextStyle()).copyWith(
        fontWeight: weight == 'bold' || weight == '700'
            ? FontWeight.bold
            : null,
        fontStyle: fontStyle == 'italic' ? FontStyle.italic : null,
        decoration: decoration?.contains('underline') == true
            ? TextDecoration.underline
            : null,
        color: color,
      );
    }
    final color = _parseColor(element.attributes['color']);
    if (color != null) {
      style = (style ?? const TextStyle()).copyWith(color: color);
    }
    return style;
  }

  static Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) return null;
    final text = value.trim().toLowerCase();
    const named = {
      'black': Color(0xff000000),
      'blue': Color(0xff0000ff),
      'green': Color(0xff008000),
      'red': Color(0xffff0000),
      'white': Color(0xffffffff),
      'yellow': Color(0xffffff00),
    };
    if (named.containsKey(text)) return named[text];
    final hex = text.startsWith('#') ? text.substring(1) : text;
    final value32 = int.tryParse(hex, radix: 16);
    if (value32 == null) return null;
    if (hex.length == 6) return Color(0xff000000 | value32);
    if (hex.length == 8) return Color(value32);
    return null;
  }
}
