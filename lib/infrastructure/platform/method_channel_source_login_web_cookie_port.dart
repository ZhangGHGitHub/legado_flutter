import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/ports/source_login_web_cookie_port.dart';

class MethodChannelSourceLoginWebCookiePort
    implements SourceLoginWebCookiePort {
  const MethodChannelSourceLoginWebCookiePort();

  static const _channel = MethodChannel('legado_flutter/source_login_cookies');

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearForSource({
    required String sourceUrl,
    required String registrableDomain,
  }) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('clearForSource', {
      'sourceUrl': sourceUrl,
      'registrableDomain': registrableDomain,
    });
  }
}
