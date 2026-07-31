import '../../application/source_management/source_group_catalog_port.dart';
import '../../services/source_group_catalog.dart' as legacy_catalog;
import '../../services/source_group_tags.dart' as legacy_tags;

/// Adapts the legacy source-group catalog and tag helpers to the application port.
final class SourceGroupCatalogPortAdapter implements SourceGroupCatalogPort {
  const SourceGroupCatalogPortAdapter();

  @override
  List<String> get names => legacy_catalog.SourceGroupCatalog.names;

  @override
  Future<void> load() => legacy_catalog.SourceGroupCatalog.load();

  @override
  Future<void> mergeFromSources(Iterable<String> fromSources) =>
      legacy_catalog.SourceGroupCatalog.mergeFromSources(fromSources);

  @override
  Future<bool> add(String name) => legacy_catalog.SourceGroupCatalog.add(name);

  @override
  Future<void> rename(String oldName, String newName) =>
      legacy_catalog.SourceGroupCatalog.rename(oldName, newName);

  @override
  Future<void> remove(String name) =>
      legacy_catalog.SourceGroupCatalog.remove(name);

  @override
  List<String> splitGroups(String raw) => legacy_tags.splitSourceGroups(raw);

  @override
  String addGroupTag(String raw, String tag) =>
      legacy_tags.addSourceGroupTag(raw, tag);

  @override
  String removeGroupTag(String raw, String tag) =>
      legacy_tags.removeSourceGroupTag(raw, tag);

  @override
  String renameGroupTag(String raw, String from, String to) =>
      legacy_tags.renameSourceGroupTag(raw, from, to);

  @override
  bool hasGroupTag(String raw, String tag) =>
      legacy_tags.sourceHasGroupTag(raw, tag);
}
