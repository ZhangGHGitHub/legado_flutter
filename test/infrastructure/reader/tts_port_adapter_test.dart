import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader/tts_port.dart';
import 'package:legado_flutter/infrastructure/reader/tts_port_adapter.dart';
import 'package:legado_flutter/services/tts_service.dart';

void main() {
  test('maps TTS state, mode and sentence controls through the port', () async {
    final adapter = TtsPortAdapter(TtsService());

    expect(adapter.state, TtsPlaybackStatePort.idle);
    expect(adapter.capability, TtsCapabilityPort.stub);
    expect(adapter.playMode, TtsPlayModePort.listEndStop);

    adapter.bindText('第一句。第二句。');
    expect(adapter.sentenceCount, 2);
    expect(adapter.currentSentence, '第一句。');

    await adapter.seekSentence(1);
    expect(adapter.sentenceIndex, 1);
    expect(adapter.currentSentence, '第二句。');
  });
}
