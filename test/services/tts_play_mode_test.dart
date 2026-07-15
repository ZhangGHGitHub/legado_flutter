import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/tts_service.dart';

void main() {
  group('TtsPlayMode', () {
    test('cycles in Jingshiro AudioPlay order', () {
      expect(TtsPlayMode.listEndStop.next(), TtsPlayMode.singleLoop);
      expect(TtsPlayMode.singleLoop.next(), TtsPlayMode.random);
      expect(TtsPlayMode.random.next(), TtsPlayMode.listLoop);
      expect(TtsPlayMode.listLoop.next(), TtsPlayMode.listEndStop);
    });
  });

  group('TtsService.splitSentences', () {
    test('splits on Chinese punctuation', () {
      final parts = TtsService.splitSentences('你好。世界！再见？');
      expect(parts, ['你好。', '世界！', '再见？']);
    });
  });
}
