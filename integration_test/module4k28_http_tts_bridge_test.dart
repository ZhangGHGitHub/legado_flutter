import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/services/http_tts_service.dart';
import 'package:legado_flutter/services/tts_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('module 4K-28 HTTP TTS completes audio and advances sentences', (
    tester,
  ) async {
    final audio = _silentWav(const Duration(milliseconds: 140));
    var requestCount = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requestCount++;
      request.response.headers.contentType = ContentType('audio', 'wav');
      request.response.contentLength = audio.length;
      request.response.add(audio);
      unawaited(request.response.close());
    });

    final tts = TtsService.instance;
    final completed = Completer<void>();
    void onCompleted() {
      if (!completed.isCompleted) completed.complete();
    }

    tts.setEngineId('http');
    tts.configureHttpTts(
      HttpTtsConfig(
        url: 'http://127.0.0.1:${server.port}/audio?text={{speakText}}',
      ),
    );
    tts.addPlaybackCompletedListener(onCompleted);

    try {
      expect(await tts.speak('第一句。第二句。'), isTrue);
      await completed.future.timeout(const Duration(seconds: 8));
      expect(requestCount, 2);
      expect(tts.state, TtsPlaybackState.idle);
      expect(tts.sentenceIndex, 1);
    } finally {
      tts.removePlaybackCompletedListener(onCompleted);
      await tts.stop();
      tts.configureHttpTts(null);
      tts.setEngineId('system');
      await server.close(force: true);
    }
  });
}

Uint8List _silentWav(Duration duration) {
  const sampleRate = 8000;
  const channels = 1;
  const bitsPerSample = 16;
  final sampleCount = sampleRate * duration.inMilliseconds ~/ 1000;
  final dataLength = sampleCount * channels * bitsPerSample ~/ 8;
  final bytes = ByteData(44 + dataLength);

  void writeAscii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(
    28,
    sampleRate * channels * bitsPerSample ~/ 8,
    Endian.little,
  );
  bytes.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
  bytes.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);
  return bytes.buffer.asUint8List();
}
