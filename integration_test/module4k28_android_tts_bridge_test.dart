import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/services/tts_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'module 4K-28 Android TTS bridge completes an utterance',
    (tester) async {
      final tts = TtsService.instance;
      await tts.ensureInitialized().timeout(const Duration(seconds: 6));
      expect(tts.capability, TtsCapability.platform);

      final completed = Completer<void>();
      void onCompleted() {
        if (!completed.isCompleted) completed.complete();
      }

      tts.addPlaybackCompletedListener(onCompleted);
      try {
        expect(
          await tts.speak('测试句子。第二句。').timeout(const Duration(seconds: 6)),
          isTrue,
        );
        await completed.future.timeout(const Duration(seconds: 5));
        expect(tts.state, TtsPlaybackState.idle);
      } finally {
        tts.removePlaybackCompletedListener(onCompleted);
        await tts.stop().timeout(const Duration(seconds: 3));
      }
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
