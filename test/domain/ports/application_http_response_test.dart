import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/application_binary_http_request_port.dart';
import 'package:legado_flutter/domain/ports/application_http_request_port.dart';

void main() {
  group('ApplicationHttpResponse', () {
    test('preserves fields and supports value semantics', () {
      const response = ApplicationHttpResponse(
        statusCode: 207,
        body: 'multi-status',
      );

      expect(response.statusCode, 207);
      expect(response.body, 'multi-status');
      expect(
        response.copyWith(body: 'updated'),
        const ApplicationHttpResponse(statusCode: 207, body: 'updated'),
      );
      expect(
        response,
        const ApplicationHttpResponse(statusCode: 207, body: 'multi-status'),
      );
    });
  });

  group('ApplicationBinaryHttpResponse', () {
    test('preserves raw bytes and supports copyWith', () {
      final bytes = Uint8List.fromList([0, 127, 255]);
      final response = ApplicationBinaryHttpResponse(
        statusCode: 206,
        contentType: 'application/octet-stream',
        body: bytes,
      );

      expect(response.statusCode, 206);
      expect(response.contentType, 'application/octet-stream');
      expect(response.body, same(bytes));
      expect(response.body, orderedEquals([0, 127, 255]));

      final copied = response.copyWith(contentType: 'image/png');
      expect(copied.contentType, 'image/png');
      expect(copied.statusCode, 206);
      expect(copied.body, same(bytes));
    });

    test('compares Uint8List bodies by content', () {
      expect(
        ApplicationBinaryHttpResponse(
          statusCode: 200,
          contentType: 'application/octet-stream',
          body: Uint8List.fromList([1, 2, 3]),
        ),
        ApplicationBinaryHttpResponse(
          statusCode: 200,
          contentType: 'application/octet-stream',
          body: Uint8List.fromList([1, 2, 3]),
        ),
      );
    });
  });
}
