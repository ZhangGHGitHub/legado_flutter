import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef AppWebViewCookieCallback =
    Future<void> Function(String pageUrl, String cookie);

class AppWebViewResult {
  const AppWebViewResult({required this.finalUrl, required this.body});

  final String finalUrl;
  final String body;
}

@visibleForTesting
abstract final class AppWebViewPageStateTestApi {
  static String htmlFromJavaScriptResult(Object result) =>
      _AppWebViewPageState.htmlFromJavaScriptResult(result);

  static Future<bool> deliverCookieHeaderIfActive({
    required bool isActive,
    required String pageUrl,
    required String cookieHeader,
    required AppWebViewCookieCallback? onCookiesChanged,
  }) => _AppWebViewPageState.deliverCookieHeaderIfActive(
    isActive: isActive,
    pageUrl: pageUrl,
    cookieHeader: cookieHeader,
    onCookiesChanged: onCookiesChanged,
  );
}

/// 通用内嵌 WebView — 对齐 Jingshiro WebViewActivity 轻量路径。
///
/// Windows / Linux 官方 `webview_flutter` 不可用时回退为外链 + 说明页。
class AppWebViewPage extends StatefulWidget {
  const AppWebViewPage({
    super.key,
    required this.title,
    this.initialUrl,
    this.htmlContent,
    this.baseUrl,
    this.headers = const {},
    this.onCookiesChanged,
    this.returnsPageResult = false,
  });

  final String title;
  final String? initialUrl;
  final String? htmlContent;
  final String? baseUrl;
  final Map<String, String> headers;
  final AppWebViewCookieCallback? onCookiesChanged;
  final bool returnsPageResult;

  static Future<void> openUrl(
    BuildContext context, {
    required String title,
    required String url,
    Map<String, String> headers = const {},
    AppWebViewCookieCallback? onCookiesChanged,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppWebViewPage(
          title: title,
          initialUrl: url,
          headers: headers,
          onCookiesChanged: onCookiesChanged,
        ),
      ),
    );
  }

  static Future<void> openHtml(
    BuildContext context, {
    required String title,
    required String html,
    String? baseUrl,
    AppWebViewCookieCallback? onCookiesChanged,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppWebViewPage(
          title: title,
          htmlContent: html,
          baseUrl: baseUrl,
          onCookiesChanged: onCookiesChanged,
        ),
      ),
    );
  }

  static Future<AppWebViewResult?> openForResult(
    BuildContext context, {
    required String title,
    required String url,
    String? html,
    Map<String, String> headers = const {},
    AppWebViewCookieCallback? onCookiesChanged,
  }) {
    final loadsHtml = html != null && html.isNotEmpty;
    return Navigator.of(context).push<AppWebViewResult>(
      MaterialPageRoute(
        builder: (_) => AppWebViewPage(
          title: title,
          initialUrl: loadsHtml ? null : url,
          htmlContent: loadsHtml ? html : null,
          baseUrl: loadsHtml ? url : null,
          headers: headers,
          onCookiesChanged: onCookiesChanged,
          returnsPageResult: true,
        ),
      ),
    );
  }

  static String cookieHeaderFor(Iterable<WebViewCookie> cookies) {
    final values = <String, String>{};
    for (final cookie in cookies) {
      final name = cookie.name.trim();
      if (name.isNotEmpty) values[name] = cookie.value;
    }
    return values.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  static bool get isWebViewSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  @override
  State<AppWebViewPage> createState() => _AppWebViewPageState();
}

class _AppWebViewPageState extends State<AppWebViewPage> {
  WebViewCookieManager? _cookieManager;
  Future<void> _cookieSync = Future<void>.value();
  WebViewController? _controller;
  var _loading = true;
  var _completing = false;
  var _disposed = false;
  String? _lastPageUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!AppWebViewPage.isWebViewSupported) {
      setState(() {
        _loading = false;
        _error = '当前平台不支持内嵌 WebView';
      });
      return;
    }
    try {
      _cookieManager = WebViewCookieManager();
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              _lastPageUrl = url;
              if (mounted) setState(() => _loading = true);
              _scheduleCookieSync(url);
            },
            onPageFinished: (url) {
              _lastPageUrl = url;
              if (mounted) setState(() => _loading = false);
              _scheduleCookieSync(url);
            },
            onWebResourceError: (e) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = e.description;
                });
              }
            },
          ),
        );
      if (widget.htmlContent != null && widget.htmlContent!.isNotEmpty) {
        await c.loadHtmlString(widget.htmlContent!, baseUrl: widget.baseUrl);
      } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
        await c.loadRequest(
          Uri.parse(widget.initialUrl!),
          headers: widget.headers,
        );
      }
      if (!mounted) return;
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _scheduleCookieSync(String pageUrl) {
    if (widget.onCookiesChanged == null || !_canSyncCookies) return;
    _cookieSync = _cookieSync.then((_) async {
      if (!_canSyncCookies) return;
      await _syncCookies(pageUrl);
    });
  }

  Future<void> _syncCookies(String pageUrl) async {
    final uri = Uri.tryParse(pageUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    if (!_canSyncCookies) return;
    try {
      final manager = _cookieManager;
      if (manager == null) return;
      final cookies = await manager.platform.getCookies(uri);
      await deliverCookieHeaderIfActive(
        isActive: _canSyncCookies,
        pageUrl: pageUrl,
        cookieHeader: AppWebViewPage.cookieHeaderFor(cookies),
        onCookiesChanged: widget.onCookiesChanged,
      );
    } catch (e) {
      debugPrint('[WebView] Cookie 同步失败: $e');
    }
  }

  bool get _canSyncCookies => mounted && !_disposed;

  static Future<bool> deliverCookieHeaderIfActive({
    required bool isActive,
    required String pageUrl,
    required String cookieHeader,
    required AppWebViewCookieCallback? onCookiesChanged,
  }) async {
    if (!isActive || onCookiesChanged == null) return false;
    await onCookiesChanged(pageUrl, cookieHeader);
    return true;
  }

  Future<void> _openExternal() async {
    final url = widget.initialUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _completeWithPageResult() async {
    if (_completing) return;
    final controller = _controller;
    if (controller == null) return;
    setState(() => _completing = true);
    try {
      final finalUrl =
          await controller.currentUrl() ??
          _lastPageUrl ??
          widget.initialUrl ??
          widget.baseUrl ??
          '';
      if (finalUrl.isNotEmpty) _scheduleCookieSync(finalUrl);
      await _cookieSync;
      final rawBody = await controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );
      final result = AppWebViewResult(
        finalUrl: finalUrl,
        body: htmlFromJavaScriptResult(rawBody),
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _completing = false;
        _error = error.toString();
      });
    }
  }

  static String htmlFromJavaScriptResult(Object result) {
    if (result is! String) return result.toString();
    final value = result.trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is String) return decoded;
      } catch (_) {}
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty)
            IconButton(
              tooltip: '浏览器打开',
              icon: const Icon(Icons.open_in_browser),
              onPressed: _openExternal,
            ),
          if (widget.returnsPageResult)
            IconButton(
              tooltip: '完成验证',
              icon: _completing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _completing ? null : _completeWithPageResult,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_controller != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_loading) const LinearProgressIndicator(),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.public,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(_error ?? '无法加载页面', textAlign: TextAlign.center),
        if (widget.htmlContent != null &&
            widget.htmlContent!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          SelectableText(
            _stripHtml(widget.htmlContent!),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('在浏览器中打开'),
            ),
          ),
        ],
      ],
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
