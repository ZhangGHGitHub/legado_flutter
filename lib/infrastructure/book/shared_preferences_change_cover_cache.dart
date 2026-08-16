import 'dart:convert';

import '../../application/book/change_cover_controller.dart';
import '../../application/preferences/shared_preferences_runtime.dart';
import '../../domain/book/book.dart';

final class SharedPreferencesChangeCoverCache
    implements ChangeCoverCandidateCachePort {
  const SharedPreferencesChangeCoverCache();

  @override
  Future<List<ChangeCoverCandidate>> load(Book book) async {
    final prefs = await SharedPreferencesRuntime.getOrNull();
    final raw = prefs?.getString(_key(book));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (value) => ChangeCoverCandidate(
              url: value['url'] as String? ?? '',
              sourceName: value['sourceName'] as String? ?? '',
              sourceOrder: (value['sourceOrder'] as num?)?.toInt() ?? 0,
              sourceUrl: value['sourceUrl'] as String? ?? '',
            ),
          )
          .where(
            (candidate) =>
                candidate.url.isNotEmpty && candidate.sourceName.isNotEmpty,
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(Book book, ChangeCoverCandidate candidate) async {
    final prefs = await SharedPreferencesRuntime.getOrNull();
    if (prefs == null) return;
    final candidates = (await load(book)).toList();
    candidates.removeWhere((item) => item.url == candidate.url);
    candidates.add(candidate);
    candidates.sort((a, b) => a.sourceOrder.compareTo(b.sourceOrder));
    await prefs.setString(
      _key(book),
      jsonEncode(
        candidates
            .take(50)
            .map(
              (item) => {
                'url': item.url,
                'sourceName': item.sourceName,
                'sourceOrder': item.sourceOrder,
                'sourceUrl': item.sourceUrl,
              },
            )
            .toList(growable: false),
      ),
    );
  }

  static String _key(Book book) {
    final identity =
        '${book.name}\n${ChangeCoverController.normalizeAuthor(book.author)}';
    return 'change_cover_${Uri.encodeComponent(identity)}';
  }
}
