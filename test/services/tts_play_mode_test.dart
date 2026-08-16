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

    test(
      'speakSelection trims the selection before sentence binding',
      () async {
        final tts = TtsService.instance;
        await tts.speakSelection('  你好。世界！  ');
        expect(tts.currentSentence, '你好。');
        expect(tts.sentenceCount, 2);
        await tts.stop();
      },
    );

    test(
      'speakFromOffset binds the remaining chapter text from the source offset',
      () async {
        final tts = TtsService.instance;
        await tts.speakFromOffset('前句。选中点。后句！', 3);
        expect(tts.currentSentence, '选中点。');
        expect(tts.currentTextOffset, 0);
        expect(tts.sentenceCount, 2);
        await tts.stop();
      },
    );

    test('selection speak mode toggles between original modes', () {
      final tts = TtsService.instance;
      tts.setSelectionSpeakMode(TtsSelectionSpeakMode.selection);
      expect(tts.readsFromSelection, isFalse);
      tts.toggleSelectionSpeakMode();
      expect(tts.selectionSpeakMode, TtsSelectionSpeakMode.continuous);
      tts.toggleSelectionSpeakMode();
      expect(tts.selectionSpeakMode, TtsSelectionSpeakMode.selection);
    });
  });
}
