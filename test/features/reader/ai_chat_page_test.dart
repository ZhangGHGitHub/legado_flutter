import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/ai/ai_config_prefs_port.dart';
import 'package:legado_flutter/features/reader/ai_chat_page.dart';

class _FakeAiConfigPrefsPort implements AiConfigPrefsPort {
  _FakeAiConfigPrefsPort(this.settings);

  AiConfigSettings settings;
  var loadCount = 0;

  @override
  Future<AiConfigSettings> load() async {
    loadCount++;
    return settings;
  }

  @override
  Future<void> save(AiConfigSettings settings) async {
    this.settings = settings;
  }

  @override
  Future<void> clearMemory() async {
    settings = settings.copyWith(memoryList: const []);
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeAiConfigPrefsPort port, {
  bool isStandalone = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AiChatPage(isStandalone: isStandalone, prefsPort: port),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('loads settings through the injected port', (tester) async {
    final port = _FakeAiConfigPrefsPort(
      const AiConfigSettings(apiKey: 'key', model: 'test-model'),
    );

    await _pumpPage(tester, port);

    expect(port.loadCount, 1);
    expect(find.text('配置已就绪'), findsOneWidget);
    expect(find.textContaining('模型：test-model'), findsOneWidget);
    expect(find.text('打开配置'), findsOneWidget);
  });

  testWidgets('keeps reader mode copy when AI is not configured', (
    tester,
  ) async {
    final port = _FakeAiConfigPrefsPort(const AiConfigSettings(apiUrl: ''));

    await _pumpPage(tester, port, isStandalone: false);

    expect(find.text('请先配置 AI'), findsOneWidget);
    expect(find.textContaining('阅读模式：从阅读器进入'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('去配置'), findsOneWidget);
  });
}
