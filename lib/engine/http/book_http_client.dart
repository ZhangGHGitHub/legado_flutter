import 'dart:convert';
import 'dart:io';

import 'package:charset_converter/charset_converter.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../models/book_source.dart';
import '../../services/cookie_jar.dart';
import '../../services/rate_limiter.dart';

/// HTTP 客户端 — 对齐 Legado `help/http/*`
class BookHttpClient {
  final CookieJar cookies = CookieJar();
  final RateLimiter rateLimiter = RateLimiter();
  late final Dio _dio;

  BookHttpClient() {
    _dio =
        Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 15),
              followRedirects: true,
              maxRedirects: 5,
              validateStatus: (_) => true,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                    'AppleWebKit/537.36 (KHTML, like Gecko) '
                    'Chrome/131.0.0.0 Safari/537.36',
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br',
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'none',
                'Sec-Fetch-User': '?1',
                'Upgrade-Insecure-Requests': '1',
                'Connection': 'keep-alive',
              },
            ),
          )
          ..httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () {
              final client = HttpClient();
              client.badCertificateCallback = (cert, host, port) => true;
              return client;
            },
          );
  }

  Dio get dio => _dio;

  Map<String, String> buildHeaders(
    BookSource source,
    String url, {
    String? referer,
  }) {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/131.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Referer': referer ?? source.bookSourceUrl,
      ...source.customHeaders,
    };
    final cookie = cookies.getCookie(url);
    if (cookie.isNotEmpty) headers['Cookie'] = cookie;
    return headers;
  }

  Future<void> applyRateLimit(BookSource source) async {
    final rate = source.concurrentRate;
    if (rate.isNotEmpty) {
      rateLimiter.configure(source.bookSourceUrl, rate);
      await rateLimiter.waitIfNeeded(source.bookSourceUrl);
    }
  }

  void saveCookies(String url, Response<dynamic> response) {
    final raw = response.headers.map;
    final setCookies = <String>[];
    raw.forEach((key, values) {
      if (key.toLowerCase() == 'set-cookie') {
        setCookies.addAll(values);
      }
    });
    if (setCookies.isNotEmpty) {
      cookies.saveFromHeaders(url, {'set-cookie': setCookies});
    }
  }

  Uint8List decompressBytes(List<int> rawBytes) {
    if (rawBytes.length >= 2 && rawBytes[0] == 0x1F && rawBytes[1] == 0x8B) {
      return Uint8List.fromList(gzip.decode(rawBytes));
    }
    return Uint8List.fromList(rawBytes);
  }

  Future<Uint8List> fetchBytes(
    String url,
    BookSource source, {
    String? referer,
  }) async {
    await applyRateLimit(source);
    final resp = await _dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: buildHeaders(source, url, referer: referer),
      ),
    );
    saveCookies(url, resp);
    return decompressBytes((resp.data as List<int>?) ?? []);
  }

  Future<Uint8List> executeRequest(
    String resolvedUrl, {
    String method = 'GET',
    String? body,
    String charset = 'UTF-8',
    BookSource? source,
  }) async {
    if (source != null) await applyRateLimit(source);

    final headers = source != null
        ? buildHeaders(source, resolvedUrl, referer: resolvedUrl)
        : <String, String>{
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/131.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate',
          };

    Response<List<int>> response;
    if (method == 'POST' && body != null) {
      final encodedBody = await _encodeFormBody(body, charset);
      response = await _dio.post(
        resolvedUrl,
        data: encodedBody,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            ...headers,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
    } else {
      response = await _dio.get(
        resolvedUrl,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
    }

    saveCookies(resolvedUrl, response);
    return decompressBytes(response.data ?? []);
  }

  Future<String> fetchString(
    String url,
    BookSource source, {
    String charset = 'UTF-8',
    String? referer,
  }) async {
    final bytes = await fetchBytes(url, source, referer: referer);
    return decodeResponse(bytes, charset: charset);
  }

  Future<String> decodeResponse(
    Uint8List rawBytes, {
    String charset = 'UTF-8',
  }) async {
    if (charset.toUpperCase() == 'UTF-8' || charset.toUpperCase() == 'UTF8') {
      try {
        return utf8.decode(rawBytes);
      } catch (_) {}
      for (final alias in [
        'gb2312',
        'GB2312',
        'GBK',
        'cp936',
        '936',
        'windows-936',
        'gb18030',
      ]) {
        try {
          return await CharsetConverter.decode(alias, rawBytes);
        } catch (_) {}
      }
      return utf8.decode(rawBytes);
    }

    final aliases = <String>{
      charset,
      if (charset == 'GBK' || charset == 'GB2312') ...[
        'gb2312',
        'GB2312',
        'cp936',
        '936',
        'windows-936',
        'gb18030',
      ],
      if (charset == 'gb18030' || charset == 'GB18030') ...[
        'gb18030',
        'gb2312',
        'GB2312',
        'cp936',
      ],
    };

    for (final alias in aliases) {
      try {
        return await CharsetConverter.decode(alias, rawBytes);
      } catch (_) {}
    }

    debugPrint('  ⚠ 所有 charset 尝试失败，回退 UTF-8');
    return utf8.decode(rawBytes);
  }

  static String normalizeCharset(String charset) {
    final lower = charset.toLowerCase();
    if (lower == 'gb2312' ||
        lower == 'gbk' ||
        lower == 'gb18030' ||
        lower == '936') {
      return '936';
    }
    if (lower == 'utf-8' || lower == 'utf8') return 'utf-8';
    return charset;
  }

  Future<String> _encodeFormBody(String body, String charset) async {
    if (charset.toUpperCase() != 'UTF-8' && charset.toUpperCase() != 'UTF8') {
      final charsetName = normalizeCharset(charset);
      final parts = body.split('&');
      final encodedParts = <String>[];
      for (final pair in parts) {
        final eqIdx = pair.indexOf('=');
        if (eqIdx <= 0) {
          encodedParts.add(pair);
          continue;
        }
        final key = pair.substring(0, eqIdx);
        final val = pair.substring(eqIdx + 1);
        final valBytes = await CharsetConverter.encode(charsetName, val);
        final encodedVal = valBytes
            .map((b) => '%${b.toRadixString(16).padLeft(2, '0').toUpperCase()}')
            .join('');
        encodedParts.add('$key=$encodedVal');
      }
      return encodedParts.join('&');
    }

    return body
        .split('&')
        .map((pair) {
          final eqIdx = pair.indexOf('=');
          if (eqIdx <= 0) return pair;
          final key = pair.substring(0, eqIdx);
          final val = pair.substring(eqIdx + 1);
          return '$key=${Uri.encodeQueryComponent(val)}';
        })
        .join('&');
  }
}
