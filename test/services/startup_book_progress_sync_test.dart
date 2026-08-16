import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/main.dart' show loadStartupBookProgress;

void main() {
  test('startup progress sync loads books before downloading', () async {
    final events = <String>[];

    final applied = await loadStartupBookProgress(
      loadBooks: () async => events.add('load'),
      enabled: true,
      downloadAllBookProgress: () async {
        events.add('download');
        return 2;
      },
    );

    expect(applied, 2);
    expect(events, ['load', 'download']);
  });

  test('disabled startup progress sync does not download', () async {
    var downloads = 0;

    final applied = await loadStartupBookProgress(
      loadBooks: () async {},
      enabled: false,
      downloadAllBookProgress: () async {
        downloads++;
        return 1;
      },
    );

    expect(applied, 0);
    expect(downloads, 0);
  });

  test('startup progress sync failure does not block startup', () async {
    final applied = await loadStartupBookProgress(
      loadBooks: () async {},
      enabled: true,
      downloadAllBookProgress: () async => throw StateError('offline'),
    );

    expect(applied, 0);
  });
}
