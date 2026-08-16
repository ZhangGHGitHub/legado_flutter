import '../../application/source_rules/replace_preview_port.dart';
import '../../domain/content/replace_rule.dart';
import '../../services/replace_service.dart' as service;

/// Exposes the existing replacement engine through the application boundary.
final class ReplacePreviewPortAdapter implements ReplacePreviewPort {
  const ReplacePreviewPortAdapter();

  @override
  String get defaultSampleText => service.ReplaceService.defaultSampleText;

  @override
  String apply(String text, List<ReplaceRule> rules) =>
      service.ReplaceService.applyWithRules(text, rules);
}
