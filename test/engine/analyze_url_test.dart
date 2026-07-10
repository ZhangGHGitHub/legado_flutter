import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/engine/analyze_url.dart';

void main() {
  group('AnalyzeUrl.parseUrlConfig', () {
    test('纯 GET URL 替换占位符', () {
      final cfg = AnalyzeUrl.parseUrlConfig(
        'https://example.com/search?key={{key}}&page={{page}}',
        '测试',
      );
      expect(cfg.method, 'GET');
      expect(cfg.url, contains(Uri.encodeComponent('测试')));
      expect(cfg.url, contains('page=1'));
    });

    test('URL + JSON POST 配置', () {
      final cfg = AnalyzeUrl.parseUrlConfig(
        '/search.php,{"body":"key={{key}}","charset":"gbk","method":"POST"}',
        'abc',
      );
      expect(cfg.method, 'POST');
      expect(cfg.body, 'key=abc');
      expect(cfg.charset, 'GBK');
    });
  });

  group('AnalyzeUrl.resolveUrl', () {
    test('相对路径补全', () {
      expect(
        AnalyzeUrl.resolveUrl('/book/1', 'http://m.example.com'),
        'http://m.example.com/book/1',
      );
    });

    test('绝对 URL 不变', () {
      const url = 'https://other.com/ch/1';
      expect(AnalyzeUrl.resolveUrl(url, 'http://m.example.com'), url);
    });
  });

  group('AnalyzeUrl.baseUrl', () {
    test('提取 scheme + host', () {
      expect(
        AnalyzeUrl.baseUrl('http://m.biqukun.org/search.php'),
        'http://m.biqukun.org',
      );
    });
  });
}
