import '../../bridge/legado_engine_bridge.dart';
import '../../domain/content/replace_rule.dart';
import '../../domain/ports/content_processing_port.dart';
import '../../src/rust/api.dart' as rust_api;

typedef RustApplyContentReplaceRules =
    String Function({
      required String text,
      required List<rust_api.ContentReplaceRuleDto> rules,
    });

typedef RustProcessContent =
    String Function({
      required String text,
      required List<rust_api.ContentReplaceRuleDto> rules,
      rust_api.ContentProcessingSourceRulesDto? sourceRules,
    });

typedef RustProcessContentForReading =
    String Function({
      required String raw,
      required String chapterTitle,
      required String bookName,
      required bool includeTitle,
      required bool useReplace,
      required String paragraphIndent,
      required bool reSegment,
      required List<rust_api.ContentReplaceRuleDto> rules,
      rust_api.ContentProcessingSourceRulesDto? sourceRules,
    });

/// Rust/FRB 正文净化适配器。
///
/// 本端口只处理正文字符串；分页、断行和章节位置仍由 Flutter 阅读链路负责。
class FrbContentProcessingPort implements ContentProcessingPort {
  FrbContentProcessingPort({
    bool Function()? isAvailable,
    RustApplyContentReplaceRules? applyContentReplaceRules,
    RustProcessContent? processContent,
    RustProcessContentForReading? processContentForReading,
  }) : _isAvailable = isAvailable ?? _defaultIsAvailable,
       _applyContentReplaceRules =
           applyContentReplaceRules ?? rust_api.applyContentReplaceRules,
       _processContent = processContent ?? rust_api.processContent,
       _processContentForReading =
           processContentForReading ?? rust_api.processContentForReading;

  final bool Function() _isAvailable;
  final RustApplyContentReplaceRules _applyContentReplaceRules;
  final RustProcessContent _processContent;
  final RustProcessContentForReading _processContentForReading;
  List<ReplaceRule> _rules = const [];

  @override
  void loadRules(List<ReplaceRule> rules) {
    _rules = List.unmodifiable(rules);
  }

  @override
  String applyWithRules(String raw, List<ReplaceRule> rules) {
    _requireAvailable();
    return _applyContentReplaceRules(text: raw, rules: _rustRulesFor(rules));
  }

  @override
  String getContent(String raw) {
    _requireAvailable();
    return _applyContentReplaceRules(text: raw, rules: _rustRules);
  }

  @override
  String process(String raw, {ContentProcessingSourceRules? sourceRules}) {
    _requireAvailable();
    return _processContent(
      text: raw,
      rules: _rustRules,
      sourceRules: _rustSourceRules(sourceRules),
    );
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
    _requireAvailable();
    return _processContentForReading(
      raw: raw,
      chapterTitle: chapterTitle,
      bookName: bookName,
      includeTitle: includeTitle,
      useReplace: useReplace,
      paragraphIndent: paragraphIndent,
      reSegment: reSegment,
      rules: _rustRules,
      sourceRules: _rustSourceRules(sourceRules),
    );
  }

  List<rust_api.ContentReplaceRuleDto> get _rustRules => _rustRulesFor(_rules);

  static List<rust_api.ContentReplaceRuleDto> _rustRulesFor(
    List<ReplaceRule> rules,
  ) => rules
      .map(
        (rule) => rust_api.ContentReplaceRuleDto(
          id: rule.id,
          name: rule.name,
          pattern: rule.pattern,
          replacement: rule.replacement,
          isEnabled: rule.isEnabled,
          isRegex: rule.isRegex,
        ),
      )
      .toList(growable: false);

  static rust_api.ContentProcessingSourceRulesDto? _rustSourceRules(
    ContentProcessingSourceRules? rules,
  ) {
    if (rules == null) return null;
    return rust_api.ContentProcessingSourceRulesDto(
      contentReplace: rules.contentReplace,
      contentReplaceTo: rules.contentReplaceTo,
    );
  }

  void _requireAvailable() {
    if (!_isAvailable()) {
      throw StateError('Rust engine not available');
    }
  }

  static bool _defaultIsAvailable() => LegadoEngineBridge.isAvailable;
}
