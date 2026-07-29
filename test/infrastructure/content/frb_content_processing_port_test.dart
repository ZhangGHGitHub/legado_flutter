import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/ports/content_processing_port.dart';
import 'package:legado_flutter/infrastructure/content/frb_content_processing_port.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;

void main() {
  test('maps replacement rules to the Rust DTO without changing order', () {
    late List<rust_api.ContentReplaceRuleDto> captured;
    final port = FrbContentProcessingPort(
      isAvailable: () => true,
      applyContentReplaceRules: ({required text, required rules}) {
        captured = rules;
        return text;
      },
    );
    port.loadRules([
      ReplaceRule(
        id: 'plain',
        name: '普通替换',
        pattern: '旧',
        replacement: '新',
        isRegex: false,
      ),
      ReplaceRule(
        id: 'disabled',
        name: '停用规则',
        pattern: r'^广告$',
        isEnabled: false,
      ),
    ]);

    expect(port.getContent('正文'), '正文');
    expect(captured.map((rule) => rule.id), ['plain', 'disabled']);
    expect(captured.first.isRegex, isFalse);
    expect(captured.last.isEnabled, isFalse);
  });

  test('maps source rules and reading options to Rust', () {
    late rust_api.ContentProcessingSourceRulesDto capturedSource;
    late bool capturedIncludeTitle;
    late bool capturedResegment;
    final port = FrbContentProcessingPort(
      isAvailable: () => true,
      processContentForReading:
          ({
            required raw,
            required chapterTitle,
            required bookName,
            required includeTitle,
            required useReplace,
            required paragraphIndent,
            required reSegment,
            required rules,
            sourceRules,
          }) {
            capturedSource = sourceRules!;
            capturedIncludeTitle = includeTitle;
            capturedResegment = reSegment;
            return raw;
          },
    );

    expect(
      port.processForReading(
        '正文',
        chapterTitle: '第一章',
        includeTitle: false,
        reSegment: false,
        sourceRules: const ContentProcessingSourceRules(
          contentReplace: '广告',
          contentReplaceTo: '',
        ),
      ),
      '正文',
    );
    expect(capturedSource.contentReplace, '广告');
    expect(capturedSource.contentReplaceTo, '');
    expect(capturedIncludeTitle, isFalse);
    expect(capturedResegment, isFalse);
  });

  test('fails explicitly when the Rust engine is unavailable', () {
    final port = FrbContentProcessingPort(isAvailable: () => false);

    expect(() => port.getContent('正文'), throwsStateError);
  });
}
