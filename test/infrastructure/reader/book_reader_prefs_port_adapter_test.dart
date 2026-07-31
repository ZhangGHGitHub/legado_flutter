import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/reader/book_reader_prefs_port_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const port = BookReaderPrefsPortAdapter();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'preserves page animation defaults and book-specific persistence',
    () async {
      final prefs = await SharedPreferences.getInstance();
      expect(await port.getPageAnim('book-1'), isNull);

      await port.setPageAnim('book-1', -1);
      expect(await port.getPageAnim('book-1'), -1);
      expect(await port.getPageAnim('book-2'), isNull);
      expect(prefs.getInt('book_page_anim:book-1'), -1);
    },
  );

  test('preserves re-segment default and book-specific persistence', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(await port.getReSegment('book-1'), isFalse);

    await port.setReSegment('book-1', true);
    expect(await port.getReSegment('book-1'), isTrue);
    expect(await port.getReSegment('book-2'), isFalse);
    expect(prefs.getBool('book_re_segment:book-1'), isTrue);
  });
}
