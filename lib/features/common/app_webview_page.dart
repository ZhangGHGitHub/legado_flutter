import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef AppWebViewCookieCallback =
    Future<void> Function(String pageUrl, String cookie);

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
  });

  final String title;
  final String? initialUrl;
  final String? htmlContent;
  final String? baseUrl;
  final Map<String, String> headers;
  final AppWebViewCookieCallback? onCookiesChanged;

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
              if (mounted) setState(() => _loading = true);
              _scheduleCookieSync(url);
            },
            onPageFinished: (url) {
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
    if (widget.onCookiesChanged == null) return;
    _cookieSync = _cookieSync.then((_) => _syncCookies(pageUrl));
  }

  Future<void> _syncCookies(String pageUrl) async {
    final uri = Uri.tryParse(pageUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    try {
      final cookies = await _cookieManager!.platform.getCookies(uri);
      await widget.onCookiesChanged!(
        pageUrl,
        AppWebViewPage.cookieHeaderFor(cookies),
      );
    } catch (e) {
      debugPrint('[WebView] Cookie 同步失败: $e');
    }
  }

  Future<void> _openExternal() async {
    final url = widget.initialUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
}
