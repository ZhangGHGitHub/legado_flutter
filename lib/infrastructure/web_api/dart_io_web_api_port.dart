import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/ports/web_api_data_port.dart';
import '../../domain/ports/web_api_port.dart';
import '../../domain/web_api_status.dart';

/// 基于 Dart IO 的本地 Web API 监听适配器。
class DartIoWebApiPort implements WebApiPort {
  DartIoWebApiPort({required WebApiDataPort dataPort}) : _dataPort = dataPort;

  final WebApiDataPort _dataPort;

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _subscription;
  String _token = '';

  @override
  bool get isAvailable => _dataPort.isAvailable;

  @override
  WebApiStatus currentStatus() {
    final server = _server;
    final running = server != null;
    final port = server?.port ?? 0;
    return WebApiStatus(
      running: running,
      port: port,
      token: running ? _token : '',
      baseUrl: running ? 'http://127.0.0.1:$port' : '',
    );
  }

  @override
  Future<WebApiStatus?> start({
    required int port,
    required String token,
  }) async {
    if (!isAvailable) return null;
    if (port < 1 || port > 65535) {
      throw ArgumentError('端口无效');
    }
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError('Token 不能为空');
    }

    await stop();

    late final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException catch (error) {
      throw Exception('绑定端口 $port 失败: $error');
    }

    _server = server;
    _token = normalizedToken;
    _subscription = server.listen(
      _dispatch,
      onError: (Object error, StackTrace stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      },
    );
    return currentStatus();
  }

  @override
  Future<void> stop() async {
    final subscription = _subscription;
    final server = _server;
    _subscription = null;
    _server = null;
    _token = '';

    await subscription?.cancel();
    await server?.close(force: true);
  }

  void _dispatch(HttpRequest request) {
    unawaited(
      _handleRequest(request).onError((error, stackTrace) {
        Zone.current.handleUncaughtError(
          error ?? StateError('Web API 请求处理失败'),
          stackTrace,
        );
      }),
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      await _route(request);
    } on WebApiDataUnavailable catch (error) {
      await _writeJson(request.response, HttpStatus.serviceUnavailable, {
        'error': error.message,
      });
    } catch (error) {
      await _writeJson(request.response, HttpStatus.internalServerError, {
        'error': _errorMessage(error),
      });
    }
  }

  Future<void> _route(HttpRequest request) async {
    final path = request.uri.path;
    if (path == '/api/health') {
      if (!_isGetOrHead(request.method)) {
        await _methodNotAllowed(request.response, const ['GET', 'HEAD']);
        return;
      }
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'ok',
        'version': '0.5.1',
      });
      return;
    }

    final segments = request.uri.pathSegments;
    if (!_isProtectedPath(segments)) {
      await _writeEmpty(request.response, HttpStatus.notFound);
      return;
    }

    if (!_isAuthorized(request)) {
      await _writeJson(request.response, HttpStatus.unauthorized, {
        'error': '无效 Token',
      });
      return;
    }

    if (segments.length == 2 &&
        segments[0] == 'api' &&
        segments[1] == 'books') {
      await _handleBooks(request);
      return;
    }
    if (segments.length == 3 &&
        segments[0] == 'api' &&
        segments[1] == 'books') {
      if (request.method != 'DELETE') {
        await _methodNotAllowed(request.response, const ['DELETE']);
        return;
      }
      await _dataPort.deleteBook(segments[2]);
      await _writeEmpty(request.response, HttpStatus.noContent);
      return;
    }
    if (segments.length == 4 &&
        segments[0] == 'api' &&
        segments[1] == 'books' &&
        segments[3] == 'chapters') {
      if (!_isGetOrHead(request.method)) {
        await _methodNotAllowed(request.response, const ['GET', 'HEAD']);
        return;
      }
      await _writeJson(
        request.response,
        HttpStatus.ok,
        await _dataPort.listChapters(segments[2]),
      );
      return;
    }
    if (segments.length == 2 &&
        segments[0] == 'api' &&
        segments[1] == 'sources') {
      if (!_isGetOrHead(request.method)) {
        await _methodNotAllowed(request.response, const ['GET', 'HEAD']);
        return;
      }
      await _writeJson(
        request.response,
        HttpStatus.ok,
        await _dataPort.listSources(),
      );
      return;
    }
    if (segments.length == 2 &&
        segments[0] == 'api' &&
        segments[1] == 'records') {
      if (!_isGetOrHead(request.method)) {
        await _methodNotAllowed(request.response, const ['GET', 'HEAD']);
        return;
      }
      await _writeJson(
        request.response,
        HttpStatus.ok,
        await _dataPort.readingStats(),
      );
      return;
    }

    await _writeEmpty(request.response, HttpStatus.notFound);
  }

  static bool _isProtectedPath(List<String> segments) {
    if (segments.length == 2 && segments[0] == 'api') {
      return segments[1] == 'books' ||
          segments[1] == 'sources' ||
          segments[1] == 'records';
    }
    if (segments.length == 3) {
      return segments[0] == 'api' && segments[1] == 'books';
    }
    return segments.length == 4 &&
        segments[0] == 'api' &&
        segments[1] == 'books' &&
        segments[3] == 'chapters';
  }

  Future<void> _handleBooks(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
      case 'HEAD':
        await _writeJson(
          request.response,
          HttpStatus.ok,
          await _dataPort.listBooks(),
        );
      case 'POST':
        final decoded = jsonDecode(await utf8.decoder.bind(request).join());
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('请求正文必须是 JSON 对象');
        }
        await _dataPort.addBook(decoded);
        await _writeEmpty(request.response, HttpStatus.created);
      default:
        await _methodNotAllowed(request.response, const [
          'GET',
          'HEAD',
          'POST',
        ]);
    }
  }

  bool _isAuthorized(HttpRequest request) {
    final authorization = request.headers.value(
      HttpHeaders.authorizationHeader,
    );
    if (authorization == null) return false;
    final normalized = authorization.trim();
    final provided = normalized.startsWith('Bearer ')
        ? normalized.substring('Bearer '.length)
        : normalized;
    return provided == _token;
  }

  static bool _isGetOrHead(String method) =>
      method == 'GET' || method == 'HEAD';

  static Future<void> _methodNotAllowed(
    HttpResponse response,
    List<String> allowed,
  ) {
    response.headers.set(HttpHeaders.allowHeader, allowed.join(','));
    return _writeEmpty(response, HttpStatus.methodNotAllowed);
  }

  static Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Object body,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }

  static Future<void> _writeEmpty(HttpResponse response, int statusCode) async {
    response.statusCode = statusCode;
    response.headers.contentType = null;
    await response.close();
  }

  static String _errorMessage(Object error) {
    final message = error.toString();
    const exceptionPrefix = 'Exception: ';
    return message.startsWith(exceptionPrefix)
        ? message.substring(exceptionPrefix.length)
        : message;
  }
}
