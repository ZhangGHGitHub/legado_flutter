import '../../domain/content/replace_rule.dart';

/// Application boundary for replacement preview behavior.
abstract interface class ReplacePreviewPort {
  String get defaultSampleText;

  String apply(String text, List<ReplaceRule> rules);
}

/// Keeps the preview usable while the composition root is being assembled.
final class UnavailableReplacePreviewPort implements ReplacePreviewPort {
  const UnavailableReplacePreviewPort();

  @override
  String get defaultSampleText => '';

  @override
  String apply(String text, List<ReplaceRule> rules) => text;
}
