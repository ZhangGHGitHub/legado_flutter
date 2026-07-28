import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/content_processing_port.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/models/replace_rule.dart';

void main() {
  test('content processing port remains replaceable', () {
    final port = _FakeContentProcessingPort();

    expect(port, isA<ContentProcessingPort>());
    expect(
      port.processForReading(
        '第一行\r\n第二行',
        chapterTitle: '第一章',
        includeTitle: false,
        useReplace: false,
        reSegment: false,
      ),
      '第一行\r\n第二行',
    );
    expect(port.lastRaw, '第一行\r\n第二行');
  });

  test('adapter delegates reading cleanup without changing line input', () {
    final adapter = ContentProcessorAdapter();
    final result = adapter.processForReading(
      '第 12 章  山雨\r\n  中文正文第一行\r\n\t中文正文第二行',
      chapterTitle: '第 12 章 山雨',
      includeTitle: false,
      paragraphIndent: '  ',
      reSegment: false,
      sourceRules: const ContentProcessingSourceRules(
        contentReplace: '正文第二行',
        contentReplaceTo: '正文末行',
      ),
    );

    expect(result, '  中文正文第一行\n  中文正文末行');
    expect(result, isNot(contains('\r')));
    expect(result, contains('中文'));
  });

  test('adapter maps source rules for the non-reading API', () {
    final adapter = ContentProcessorAdapter();
    adapter.loadRules([
      ReplaceRule(
        id: 'content-processing-adapter-test',
        name: 'content-processing-adapter-test',
        pattern: '广告词',
        replacement: '',
        isRegex: false,
      ),
    ]);

    expect(
      adapter.process(
        '广告词 正文',
        sourceRules: const ContentProcessingSourceRules(
          contentReplace: r'正文',
          contentReplaceTo: '章节',
        ),
      ),
      ' 章节',
    );
  });
}

class _FakeContentProcessingPort implements ContentProcessingPort {
  String? lastRaw;

  @override
  void loadRules(List<ReplaceRule> rules) {}

  @override
  String getContent(String raw) => raw;

  @override
  String process(String raw, {ContentProcessingSourceRules? sourceRules}) {
    lastRaw = raw;
    return raw;
  }

  @override
  String processForReading(
    String raw, {
    String chapterTitle = '',
    String bookName = '',
    bool includeTitle = true,
    bool useReplace = true,
    String paragraphIndent = '',
    bool reSegment = true,
    ContentProcessingSourceRules? sourceRules,
  }) {
    lastRaw = raw;
    return raw;
  }
}
