import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../widgets/empty_state.dart';

/// 阅读记录 — 对齐 ReadRecordActivity + LegadoRecord Web
class ReadRecordPage extends StatefulWidget {
  const ReadRecordPage({super.key});

  static const recordUrl = 'https://jingshiro.github.io/LegadoRecord/';

  @override
  State<ReadRecordPage> createState() => _ReadRecordPageState();
}

class _ReadRecordPageState extends State<ReadRecordPage> {
  WebViewController? _controller;
  bool _useWebView = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _useWebView = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(ReadRecordPage.recordUrl));
      _controller = controller;
    } catch (_) {
      _useWebView = false;
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(ReadRecordPage.recordUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: '在浏览器打开',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _useWebView && _controller != null
          ? Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            )
          : EmptyState(
              icon: Icons.history,
              title: '阅读记录',
              subtitle: '无法在应用内加载 WebView\n${ReadRecordPage.recordUrl}',
              actionLabel: '在浏览器打开',
              onAction: _openInBrowser,
            ),
    );
  }
}
