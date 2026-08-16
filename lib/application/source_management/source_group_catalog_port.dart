/// Application boundary for source-group catalog persistence and tag rules.
abstract interface class SourceGroupCatalogPort {
  List<String> get names;

  Future<void> load();

  Future<void> mergeFromSources(Iterable<String> fromSources);

  Future<bool> add(String name);

  Future<void> rename(String oldName, String newName);

  Future<void> remove(String name);

  List<String> splitGroups(String raw);

  String addGroupTag(String raw, String tag);

  String removeGroupTag(String raw, String tag);

  String renameGroupTag(String raw, String from, String to);

  bool hasGroupTag(String raw, String tag);
}

/// No-op catalog used until the composition root supplies the infrastructure adapter.
final class UnavailableSourceGroupCatalogPort
    implements SourceGroupCatalogPort {
  const UnavailableSourceGroupCatalogPort();

  @override
  List<String> get names => const [];

  @override
  Future<void> load() async {}

  @override
  Future<void> mergeFromSources(Iterable<String> fromSources) async {}

  @override
  Future<bool> add(String name) => Future.value(false);

  @override
  Future<void> rename(String oldName, String newName) async {}

  @override
  Future<void> remove(String name) async {}

  @override
  List<String> splitGroups(String raw) => _splitGroups(raw);

  @override
  String addGroupTag(String raw, String tag) =>
      _joinGroups([..._splitGroups(raw), tag]);

  @override
  String removeGroupTag(String raw, String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return _joinGroups(_splitGroups(raw));
    return _joinGroups(_splitGroups(raw).where((item) => item != trimmed));
  }

  @override
  String renameGroupTag(String raw, String from, String to) {
    final fromTag = from.trim();
    final toTag = to.trim();
    if (fromTag.isEmpty) return _joinGroups(_splitGroups(raw));
    return _joinGroups(
      _splitGroups(raw).map((item) => item == fromTag ? toTag : item),
    );
  }

  @override
  bool hasGroupTag(String raw, String tag) {
    final trimmed = tag.trim();
    return trimmed.isNotEmpty && _splitGroups(raw).contains(trimmed);
  }
}

final _groupDelimiter = RegExp(r'[,，]');

List<String> _splitGroups(String raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final part in raw.split(_groupDelimiter)) {
    final tag = part.trim();
    if (tag.isEmpty || !seen.add(tag)) continue;
    result.add(tag);
  }
  return result;
}

String _joinGroups(Iterable<String> tags) {
  final seen = <String>{};
  final result = <String>[];
  for (final tag in tags) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    result.add(trimmed);
  }
  return result.join(',');
}
