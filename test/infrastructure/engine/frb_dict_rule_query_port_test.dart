import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/rules/dict_rule.dart';
import 'package:legado_flutter/infrastructure/engine/frb_dict_rule_query_port.dart';
import 'package:legado_flutter/services/dict_rule_prefs.dart';

DictRule _defaultRule(String name) =>
    DictRulePrefs.defaultRules.singleWhere((rule) => rule.name == name);

String _dataUrl(String body, {String mimeType = 'text/html'}) =>
    'data:$mimeType;base64,${base64Encode(utf8.encode(body))}';

DictRule _offlineBaiduRule(String word, Map<String, dynamic> response) {
  final original = _defaultRule('百度汉语');
  final fixtureBody = jsonEncode(response);
  final showRule = original.showRule.replaceFirst(
    RegExp(r'^\s*result = java\.ajax\([^\r\n]+\);\s*$', multiLine: true),
    '    result = ${jsonEncode(fixtureBody)};',
  );
  if (showRule == original.showRule) {
    throw StateError('百度汉语 fixture 未替换远程请求');
  }
  return original.copyWith(
    urlRule: _dataUrl(word, mimeType: 'text/plain'),
    showRule: showRule,
  );
}

void main() {
  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);
  });

  test('FRB 字典端口执行 data URL 和 JS showRule', () async {
    const port = FrbDictRuleQueryPort();
    final result = await port.query(
      const DictRule(
        name: 'fixture',
        urlRule: 'data:text/plain;base64,5rWL6K+V',
        showRule: "@js:result + '完成'",
      ),
      'unused',
    );

    expect(result, '测试完成');
  });

  test('FRB 字典端口保留 Rust SSRF 拒绝', () async {
    const port = FrbDictRuleQueryPort();

    expect(
      port.query(
        const DictRule(name: 'private', urlRule: 'http://127.0.0.1/private'),
        'word',
      ),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('SSRF'),
          '包含 SSRF 拒绝原因',
        ),
      ),
    );
  });

  test('内置海词英文和中文规则运行离线 HTML fixture', () async {
    const port = FrbDictRuleQueryPort();
    final english = _defaultRule('海词英文').copyWith(
      urlRule: _dataUrl('<html><body><p>english definition</p></body></html>'),
    );
    final chinese = _defaultRule('海词中文').copyWith(
      urlRule: _dataUrl('''
<html><body>
  <script>remove me</script><header id="header">remove me</header>
  <div id="cy"><p>中文释义</p><span class="keep">保留内容</span></div>
  <footer id="footer">remove me</footer>
</body></html>
'''),
    );

    expect(
      await port.query(english, 'word'),
      '<body><p>english definition</p></body>',
    );
    final chineseResult = await port.query(chinese, '词');
    expect(chineseResult, contains('<p>中文释义</p>'));
    expect(chineseResult, contains('<span class="keep">保留内容</span>'));
    expect(chineseResult, isNot(contains('remove me')));
  });

  test('内置有道规则运行离线翻译 fixture', () async {
    const port = FrbDictRuleQueryPort();
    final rule = _defaultRule('有道').copyWith(
      urlRule: _dataUrl('''
<html><body>
  <div id="inputText">hello world</div>
  <div id="translateResult">你好世界</div>
</body></html>
'''),
    );

    expect(
      await port.query(rule, 'hello world'),
      '原文：<br>hello world<br>翻译：<br>你好世界',
    );
  });

  test('内置哔哩规则运行离线 DOM 修改 fixture', () async {
    const port = FrbDictRuleQueryPort();
    final html = '''
<html><body><div class="search-page">
  <a href="https://www.bilibili.com/video/BV1TEST">
    <img src="cover.jpg"><h3>视频标题</h3>
  </a>
  <a href="https://space.bilibili.com/42"><button>用户主页</button></a>
</div></body></html>
''';
    final rule = _defaultRule('哔哩').copyWith(
      urlRule: "@js:cache.putMemory('blkey',key);'${_dataUrl(html)}';",
    );

    final result = await port.query(rule, '测试');
    expect(
      result,
      contains('搜索词：<a href="bilibili://search?keyword=测试">测试</a>'),
    );
    expect(result, contains('<h3><a href="bilibili://video/BV1TEST">视频标题</a>'));
    expect(result, contains('href="bilibili://space/42"'));
    expect(result, isNot(contains('<img')));
    expect(result, isNot(contains('https://www.bilibili.com/video')));
  });

  test('内置百度汉语规则保持单命中 JsonPath 列表语义', () async {
    const port = FrbDictRuleQueryPort();
    final rule = _offlineBaiduRule('测', {
      'data': {
        'comprehensiveDefinition': [
          {
            'pinyin': 'ce4',
            'basicDefinition': [
              {
                'cixing': ['动'],
                'definition': '检验',
              },
            ],
            'detailDefinition': [
              {
                'cixing': ['名'],
                'definition': '测量',
              },
            ],
          },
        ],
        'baikeInfo': {'baikeMean': '百科释义'},
      },
    });

    final result = await port.query(rule, '测');
    expect(result, contains('<h3>ce4</h3>'));
    expect(result, contains('[动] 检验'));
    expect(result, contains('[名] 测量'));
    expect(result, contains('<b>百科释义</b>'));
    expect(result, isNot(contains('没有这个词')));
  });

  test('内置百度汉语规则运行离线成语分支', () async {
    const port = FrbDictRuleQueryPort();
    final rule = _offlineBaiduRule('测试', {
      'data': {
        'idiomVersion': '1',
        'pinyin': 'ce4 shi4',
        'story': ['成语故事'],
        'definitionInfo': {
          'definition': '基本解释',
          'detailMeans': [
            {'word': '测试', 'definition': '详细解释'},
          ],
        },
        'baobian': '变体',
        'chuChu': [
          {
            'citeOriginalText': '出处原文',
            'dynasty': '唐',
            'author': '作者',
            'source': '书名',
            'sourceChapter': '第一章',
          },
        ],
        'baikeInfo': {'baikeMean': '百科释义'},
      },
    });

    final result = await port.query(rule, '测试');
    expect(result, contains('<h3>ce4 shi4</h3>'));
    expect(result, contains('基本释义 [变体]'));
    expect(result, contains('测试：详细解释'));
    expect(result, contains('成语故事'));
    expect(result, contains('出处原文--唐●作者●书名-第一章'));
    expect(result, isNot(contains('没有这个词')));
  });
}
