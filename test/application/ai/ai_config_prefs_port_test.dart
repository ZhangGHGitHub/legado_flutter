import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/ai/ai_config_prefs_port.dart';

void main() {
  test('keeps AI defaults and copies only requested settings', () {
    const settings = AiConfigSettings();

    expect(settings.apiUrl, AiConfigSettings.defaultApiUrl);
    expect(settings.model, AiConfigSettings.defaultModel);
    expect(settings.persona, AiConfigSettings.defaultPersona);
    expect(settings.apiKey, isEmpty);
    expect(settings.toolEnabled, isTrue);
    expect(settings.memoryList, isEmpty);

    final changed = settings.copyWith(apiKey: 'secret', toolEnabled: false);
    expect(changed.apiKey, 'secret');
    expect(changed.toolEnabled, isFalse);
    expect(changed.apiUrl, settings.apiUrl);
    expect(changed.model, settings.model);
    expect(changed.persona, settings.persona);
  });

  test('uses the same preview truncation boundary as the legacy model', () {
    const short = AiMemoryItem(id: 1, chapterRange: '', content: 'short');
    const long = AiMemoryItem(
      id: 2,
      chapterRange: '',
      content: '1234567890123456',
    );

    expect(short.preview, 'short');
    expect(long.preview, '123456789012345...');
  });
}
