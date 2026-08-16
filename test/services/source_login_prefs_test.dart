import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/source_login_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SourceLoginPrefs.parseLoginHeader', () {
    test('parses JSON object map', () {
      final h = SourceLoginPrefs.parseLoginHeader(
        '{"Authorization":"Bearer t","X-Token":"abc"}',
      );
      expect(h['Authorization'], 'Bearer t');
      expect(h['X-Token'], 'abc');
    });

    test('non-JSON becomes Cookie', () {
      final h = SourceLoginPrefs.parseLoginHeader('sid=1; token=2');
      expect(h, {'Cookie': 'sid=1; token=2'});
    });

    test('empty yields empty', () {
      expect(SourceLoginPrefs.parseLoginHeader('  '), isEmpty);
    });
  });

  group('SourceLoginPrefs.mergeLoginHeaderIntoSourceJson', () {
    test('merges login over source header object', () {
      final src = jsonEncode({
        'bookSourceUrl': 'https://ex.com',
        'header': {'User-Agent': 'UA', 'Cookie': 'old'},
      });
      final out = SourceLoginPrefs.mergeLoginHeaderIntoSourceJson(
        src,
        '{"Cookie":"new","Authorization":"Bearer x"}',
      );
      final obj = jsonDecode(out) as Map<String, dynamic>;
      final header = Map<String, dynamic>.from(obj['header'] as Map);
      expect(header['User-Agent'], 'UA');
      expect(header['Cookie'], 'new');
      expect(header['Authorization'], 'Bearer x');
    });

    test('merges into string header field', () {
      final src = jsonEncode({
        'bookSourceUrl': 'https://ex.com',
        'header': '{"Accept":"text/html"}',
      });
      final out = SourceLoginPrefs.mergeLoginHeaderIntoSourceJson(
        src,
        'a=1; b=2',
      );
      final obj = jsonDecode(out) as Map<String, dynamic>;
      final header = Map<String, dynamic>.from(obj['header'] as Map);
      expect(header['Accept'], 'text/html');
      expect(header['Cookie'], 'a=1; b=2');
    });

    test('null or empty login leaves json unchanged', () {
      const src = '{"bookSourceUrl":"https://ex.com"}';
      expect(SourceLoginPrefs.mergeLoginHeaderIntoSourceJson(src, null), src);
      expect(SourceLoginPrefs.mergeLoginHeaderIntoSourceJson(src, '  '), src);
    });
  });

  test('persists and clears a full source cookie string', () async {
    const sourceUrl = 'https://www.example.com';
    await SourceLoginPrefs.saveCookie(sourceUrl, 'sid=1; token=2');
    expect(await SourceLoginPrefs.loadCookie(sourceUrl), 'sid=1; token=2');

    await SourceLoginPrefs.clearCookie(sourceUrl);
    expect(await SourceLoginPrefs.loadCookie(sourceUrl), isNull);
  });
}
