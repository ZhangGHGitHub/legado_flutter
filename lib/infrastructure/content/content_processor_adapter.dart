import '../../domain/content/replace_rule.dart';
import '../../domain/ports/content_processing_port.dart';
import '../../help/content_processor.dart';

/// 现有 [ContentProcessor] 的正文处理端口适配器。
class ContentProcessorAdapter implements ContentProcessingPort {
  final ContentProcessor _processor;

  ContentProcessorAdapter({ContentProcessor? processor})
    : _processor = processor ?? ContentProcessor.instance;

  @override
  void loadRules(List<ReplaceRule> rules) {
    _processor.loadRules(rules);
  }

  @override
  String getContent(String raw) => _processor.getContent(raw);

  @override
  String process(String raw, {ContentProcessingSourceRules? sourceRules}) {
    return _processor.process(raw, sourceRules: _toLegacyRules(sourceRules));
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
    return _processor.processForReading(
      raw,
      chapterTitle: chapterTitle,
      bookName: bookName,
      includeTitle: includeTitle,
      useReplace: useReplace,
      paragraphIndent: paragraphIndent,
      reSegment: reSegment,
      sourceRules: _toLegacyRules(sourceRules),
    );
  }

  static BookSourceRules? _toLegacyRules(ContentProcessingSourceRules? rules) {
    if (rules == null) return null;
    return BookSourceRules(
      contentReplace: rules.contentReplace,
      contentReplaceTo: rules.contentReplaceTo,
    );
  }
}
