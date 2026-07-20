/// Comma-separated multi-group tags for `bookSourceGroup`.
///
/// Splits on `,` and `，`, trims, drops empty segments, dedupes in order.

final _groupDelimiter = RegExp(r'[,，]');

List<String> splitSourceGroups(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in raw.split(_groupDelimiter)) {
    final tag = part.trim();
    if (tag.isEmpty || seen.contains(tag)) continue;
    seen.add(tag);
    out.add(tag);
  }
  return out;
}

String joinSourceGroups(Iterable<String> tags) {
  final seen = <String>{};
  final out = <String>[];
  for (final tag in tags) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) continue;
    seen.add(trimmed);
    out.add(trimmed);
  }
  return out.join(',');
}

String addSourceGroupTag(String raw, String tag) {
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return joinSourceGroups(splitSourceGroups(raw));
  final tags = splitSourceGroups(raw);
  if (tags.contains(trimmed)) return joinSourceGroups(tags);
  return joinSourceGroups([...tags, trimmed]);
}

String removeSourceGroupTag(String raw, String tag) {
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return joinSourceGroups(splitSourceGroups(raw));
  return joinSourceGroups(
    splitSourceGroups(raw).where((t) => t != trimmed),
  );
}

String renameSourceGroupTag(String raw, String from, String to) {
  final fromTag = from.trim();
  final toTag = to.trim();
  if (fromTag.isEmpty) return joinSourceGroups(splitSourceGroups(raw));
  final tags = splitSourceGroups(raw);
  final renamed = tags.map((t) => t == fromTag ? toTag : t).toList();
  return joinSourceGroups(renamed);
}

bool sourceHasGroupTag(String raw, String tag) {
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return false;
  return splitSourceGroups(raw).contains(trimmed);
}
