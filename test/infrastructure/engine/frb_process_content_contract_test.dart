import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:legado_flutter/src/rust/api/error.dart';
import 'package:legado_flutter/src/rust/frb_generated.dart';

void main() {
  late _FakeEngineApi api;

  setUpAll(() {
    api = _FakeEngineApi();
    LegadoEngine.initMock(api: api);
  });

  tearDown(() {
    api.result = '处理后正文';
    api.error = null;
  });

  test('processContentForReading forwards arguments and returns content', () {
    final result = rust_api.processContentForReading(
      raw: '原文',
      chapterTitle: '章节',
      bookName: '书名',
      includeTitle: true,
      useReplace: false,
      paragraphIndent: '  ',
      reSegment: false,
      rules: const [],
    );

    expect(result, '处理后正文');
    expect(api.raw, '原文');
    expect(api.chapterTitle, '章节');
    expect(api.bookName, '书名');
    expect(api.includeTitle, isTrue);
    expect(api.paragraphIndent, '  ');
  });

  test('processContentForReading preserves structured parse failures', () {
    api.error = const AppError.parse('正文处理失败: 原始错误');

    expect(
      () => rust_api.processContentForReading(
        raw: '原文',
        chapterTitle: '章节',
        bookName: '书名',
        includeTitle: false,
        useReplace: false,
        paragraphIndent: '',
        reSegment: false,
        rules: const [],
      ),
      throwsA(
        isA<AppError_Parse>().having(
          (error) => error.field0,
          'original message',
          '正文处理失败: 原始错误',
        ),
      ),
    );
  });
}

class _FakeEngineApi implements LegadoEngineApi {
  String? raw;
  String? chapterTitle;
  String? bookName;
  bool? includeTitle;
  String? paragraphIndent;
  String result = '处理后正文';
  AppError? error;

  @override
  String crateApiProcessContentForReading({
    required String raw,
    required String chapterTitle,
    required String bookName,
    required bool includeTitle,
    required bool useReplace,
    required String paragraphIndent,
    required bool reSegment,
    required List<rust_api.ContentReplaceRuleDto> rules,
    rust_api.ContentProcessingSourceRulesDto? sourceRules,
  }) {
    if (error case final error?) {
      throw error;
    }
    this.raw = raw;
    this.chapterTitle = chapterTitle;
    this.bookName = bookName;
    this.includeTitle = includeTitle;
    this.paragraphIndent = paragraphIndent;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('未预期的 Rust API 调用: ${invocation.memberName}');
  }
}
