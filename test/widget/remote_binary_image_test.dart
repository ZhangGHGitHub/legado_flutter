import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';
import 'package:legado_flutter/widgets/remote_binary_image.dart';
import 'package:provider/provider.dart';

class _FakeBinaryHttpPort implements ApplicationBinaryHttpRequestPort {
  final response = ApplicationBinaryHttpResponse(
    statusCode: 200,
    contentType: 'image/png',
    body: Uint8List.fromList(
      image_lib.encodePng(image_lib.Image(width: 2, height: 3)),
    ),
  );
  int calls = 0;
  String? url;
  Map<String, String>? headers;
  int? timeoutSeconds;
  int? maxResponseBytes;
  ApplicationHttpPolicy? policy;

  @override
  Future<ApplicationBinaryHttpResponse> send({
    required String url,
    required String method,
    Map<String, String> headers = const {},
    Uint8List? body,
    int timeoutSeconds = 30,
    int maxResponseBytes = 0,
    required ApplicationHttpPolicy policy,
  }) async {
    calls++;
    this.url = url;
    this.headers = Map.of(headers);
    this.timeoutSeconds = timeoutSeconds;
    this.maxResponseBytes = maxResponseBytes;
    this.policy = policy;
    return response;
  }
}

void main() {
  setUp(RemoteBinaryImage.clearMemoryCache);

  testWidgets('loads bytes through the requested network policy', (
    tester,
  ) async {
    final port = _FakeBinaryHttpPort();
    await tester.pumpWidget(
      Provider<ApplicationBinaryHttpRequestPort>.value(
        value: port,
        child: const MaterialApp(
          home: RemoteBinaryImage(
            url: ' https://example.com/cover.png ',
            headers: {'Cookie': 'reader=1'},
            policy: ApplicationHttpPolicy.publicOnly,
            width: 40,
            height: 60,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(port.calls, 1);
    expect(port.url, 'https://example.com/cover.png');
    expect(port.headers, {'Cookie': 'reader=1'});
    expect(port.timeoutSeconds, 20);
    expect(port.maxResponseBytes, RemoteBinaryImage.maxResponseBytes);
    expect(port.policy, ApplicationHttpPolicy.publicOnly);
  });

  testWidgets('coalesces and reuses the same URL and headers', (tester) async {
    final port = _FakeBinaryHttpPort();
    await tester.pumpWidget(
      Provider<ApplicationBinaryHttpRequestPort>.value(
        value: port,
        child: const MaterialApp(
          home: Row(
            children: [
              RemoteBinaryImage(url: 'https://example.com/a.png'),
              RemoteBinaryImage(url: 'https://example.com/a.png'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(port.calls, 1);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('uses the placeholder when the port is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RemoteBinaryImage(
          url: 'https://example.com/a.png',
          placeholderBuilder: _testPlaceholder,
        ),
      ),
    );
    expect(find.text('placeholder'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

Widget _testPlaceholder(BuildContext context) => const Text('placeholder');
