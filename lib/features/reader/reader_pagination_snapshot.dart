import 'dart:convert';

import 'reader_paginator.dart';

/// The fixed rendering inputs required to compare a reader page layout.
class ReaderPaginationSnapshotConfig {
  final String fontFamily;
  final double fontSize;
  final int fontWeight;
  final double devicePixelRatio;
  final double viewportWidth;
  final double viewportHeight;
  final double contentLeft;
  final double contentTop;
  final double contentWidth;
  final double contentHeight;
  final double lineHeight;
  final double renderedLineHeight;
  final double letterSpacing;
  final double paragraphSpacingTenths;
  final String pageMode;
  final bool textFullJustify;
  final double titleFontSize;
  final int titleFontWeight;

  const ReaderPaginationSnapshotConfig({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.devicePixelRatio,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.contentLeft,
    required this.contentTop,
    required this.contentWidth,
    required this.contentHeight,
    required this.lineHeight,
    required this.renderedLineHeight,
    required this.letterSpacing,
    required this.paragraphSpacingTenths,
    required this.pageMode,
    this.textFullJustify = false,
    this.titleFontSize = 0,
    this.titleFontWeight = 400,
  });

  Map<String, dynamic> toJson() => {
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'fontWeight': fontWeight,
    'devicePixelRatio': devicePixelRatio,
    'viewport': {
      'width': viewportWidth,
      'height': viewportHeight,
      'physicalWidth': viewportWidth * devicePixelRatio,
      'physicalHeight': viewportHeight * devicePixelRatio,
    },
    'content': {
      'left': contentLeft,
      'top': contentTop,
      'width': contentWidth,
      'height': contentHeight,
    },
    'lineHeight': lineHeight,
    'renderedLineHeight': renderedLineHeight,
    'letterSpacing': letterSpacing,
    'paragraphSpacingTenths': paragraphSpacingTenths,
    'pageMode': pageMode,
    'textFullJustify': textFullJustify,
    'title': {
      'fontSize': titleFontSize == 0 ? fontSize : titleFontSize,
      'fontWeight': titleFontWeight,
    },
  };

  factory ReaderPaginationSnapshotConfig.fromJson(Map<String, dynamic> json) {
    final viewport = _map(json['viewport']);
    final content = _map(json['content']);
    return ReaderPaginationSnapshotConfig(
      fontFamily: json['fontFamily'] as String? ?? '',
      fontSize: _double(json['fontSize']),
      fontWeight: (json['fontWeight'] as num?)?.toInt() ?? 400,
      devicePixelRatio: _double(json['devicePixelRatio'], fallback: 1),
      viewportWidth: _double(viewport['width']),
      viewportHeight: _double(viewport['height']),
      contentLeft: _double(content['left']),
      contentTop: _double(content['top']),
      contentWidth: _double(content['width']),
      contentHeight: _double(content['height']),
      lineHeight: _double(json['lineHeight']),
      renderedLineHeight: _double(
        json['renderedLineHeight'],
        fallback: _double(json['fontSize']) * _double(json['lineHeight']),
      ),
      letterSpacing: _double(json['letterSpacing']),
      paragraphSpacingTenths: _double(json['paragraphSpacingTenths']),
      pageMode: json['pageMode'] as String? ?? 'horizontal',
      textFullJustify: json['textFullJustify'] as bool? ?? false,
      titleFontSize: _double(_map(json['title'])['fontSize']),
      titleFontWeight:
          (_map(json['title'])['fontWeight'] as num?)?.toInt() ??
          (json['fontWeight'] as num?)?.toInt() ??
          400,
    );
  }
}

class ReaderPageSnapshot {
  final int index;
  final String text;
  final int start;
  final int end;

  const ReaderPageSnapshot({
    required this.index,
    required this.text,
    required this.start,
    required this.end,
  });

  factory ReaderPageSnapshot.fromSlice(int index, ReaderPageSlice page) {
    return ReaderPageSnapshot(
      index: index,
      text: page.text,
      start: page.start,
      end: page.end,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'text': text,
    'start': start,
    'end': end,
  };

  factory ReaderPageSnapshot.fromJson(Map<String, dynamic> json) {
    return ReaderPageSnapshot(
      index: (json['index'] as num).toInt(),
      text: json['text'] as String,
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );
  }
}

/// Serializable page data used by the original-vs-rewrite comparison.
class ReaderPaginationSnapshot {
  static const schemaVersion = 1;

  final String fixtureId;
  final int sourceTextLength;
  final int chapterIndex;
  final int chapterCount;
  final int chapterStart;
  final int chapterEnd;
  final ReaderPaginationSnapshotConfig config;
  final List<ReaderPageSnapshot> pages;

  const ReaderPaginationSnapshot({
    required this.fixtureId,
    required this.sourceTextLength,
    required this.chapterIndex,
    required this.chapterCount,
    required this.chapterStart,
    required this.chapterEnd,
    required this.config,
    required this.pages,
  });

  factory ReaderPaginationSnapshot.fromSlices({
    required String fixtureId,
    required String sourceText,
    required int chapterIndex,
    required int chapterCount,
    required int chapterStart,
    required int chapterEnd,
    required ReaderPaginationSnapshotConfig config,
    required List<ReaderPageSlice> pages,
  }) {
    return ReaderPaginationSnapshot(
      fixtureId: fixtureId,
      sourceTextLength: sourceText.length,
      chapterIndex: chapterIndex,
      chapterCount: chapterCount,
      chapterStart: chapterStart,
      chapterEnd: chapterEnd,
      config: config,
      pages: [
        for (var i = 0; i < pages.length; i++)
          ReaderPageSnapshot.fromSlice(i, pages[i]),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'fixtureId': fixtureId,
    'sourceTextLength': sourceTextLength,
    'chapter': {
      'index': chapterIndex,
      'count': chapterCount,
      'start': chapterStart,
      'end': chapterEnd,
    },
    'config': config.toJson(),
    'pages': [for (final page in pages) page.toJson()],
  };

  String encode() => jsonEncode(toJson());

  factory ReaderPaginationSnapshot.fromJson(Map<String, dynamic> json) {
    final chapter = _map(json['chapter']);
    final rawPages = (json['pages'] as List<dynamic>? ?? const []);
    return ReaderPaginationSnapshot(
      fixtureId: json['fixtureId'] as String? ?? '',
      sourceTextLength: (json['sourceTextLength'] as num).toInt(),
      chapterIndex: (chapter['index'] as num).toInt(),
      chapterCount: (chapter['count'] as num).toInt(),
      chapterStart: (chapter['start'] as num).toInt(),
      chapterEnd: (chapter['end'] as num).toInt(),
      config: ReaderPaginationSnapshotConfig.fromJson(_map(json['config'])),
      pages: [
        for (final page in rawPages) ReaderPageSnapshot.fromJson(_map(page)),
      ],
    );
  }

  /// Returns invariant violations instead of silently accepting a bad baseline.
  List<String> validate(String sourceText) {
    final errors = <String>[];
    if (sourceText.length != sourceTextLength) {
      errors.add('sourceTextLength does not match source');
    }
    if (chapterStart < 0 ||
        chapterEnd < chapterStart ||
        chapterEnd > sourceText.length) {
      errors.add('chapter boundary is outside source');
    }
    var previousEnd = 0;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (page.index != i) errors.add('page $i has index ${page.index}');
      if (page.start < previousEnd ||
          page.start < 0 ||
          page.end < page.start ||
          page.end > sourceText.length) {
        errors.add('page $i has invalid source range');
        continue;
      }
      final sourcePageText = sourceText.substring(page.start, page.end);
      if (page.text != sourcePageText && page.text != '$sourcePageText\n') {
        errors.add('page $i text does not match source range');
      }
      final gap = sourceText.substring(previousEnd, page.start);
      if (gap.isNotEmpty &&
          !RegExp(r'^\s*\[newpage\]\s*\n?\s*$').hasMatch(gap)) {
        errors.add('page $i skips non-layout source text');
      }
      previousEnd = page.end;
    }
    final tail = sourceText.substring(previousEnd);
    if (tail.isNotEmpty &&
        !RegExp(r'^\s*\[newpage\]\s*\n?\s*$').hasMatch(tail)) {
      errors.add('snapshot does not cover source tail');
    }
    return errors;
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

double _double(Object? value, {double fallback = 0}) {
  return value is num ? value.toDouble() : fallback;
}
