import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  });

  final String title;
  final String? initialUrl;
  final String? htmlContent;
  final String? baseUrl;

  static Future<void> openUrl(
    BuildContext context, {
    required String title,
    required String url,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppWebViewPage(title: title, initialUrl: url),
      ),
    );
  }

  static Future<void> openHtml(
    BuildContext context, {
    required String title,
    required String html,
    String? baseUrl,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppWebViewPage(
          title: title,
          htmlContent: html,
          baseUrl: baseUrl,
        ),
      ),
    );
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
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
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
        await c.loadHtmlString(
          widget.htmlContent!,
          baseUrl: widget.baseUrl,
        );
      } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
        await c.loadRequest(Uri.parse(widget.initialUrl!));
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
        Text(
          _error ?? '无法加载页面',
          textAlign: TextAlign.center,
        ),
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
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
