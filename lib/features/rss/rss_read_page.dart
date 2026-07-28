import 'package:flutter/material.dart';

import '../../models/rss_article.dart';
import '../../models/rss_source.dart';
import '../../services/rss_service.dart';
import '../../pages/common/app_webview_page.dart';

/// RSS 阅读 — 对齐 Jingshiro 文章阅读：优先 ruleContent，否则 WebView 打开 link。
class RssReadPage extends StatefulWidget {
  const RssReadPage({super.key, required this.source, required this.article});

  final RssSource source;
  final RssArticle article;

  @override
  State<RssReadPage> createState() => _RssReadPageState();
}

class _RssReadPageState extends State<RssReadPage> {
  var _loading = true;
  String? _html;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final article = widget.article;
    final source = widget.source;

    // 已有正文/描述且无 ruleContent → 直接展示
    if (source.ruleContent.trim().isEmpty) {
      final body = article.content ?? article.description;
      if (body != null && body.trim().isNotEmpty) {
        setState(() {
          _html = _wrapHtml(body, article.title);
          _loading = false;
        });
        return;
      }
      // 无正文 → 内嵌打开原文链接
      if (!mounted) return;
      await AppWebViewPage.openUrl(
        context,
        title: article.title,
        url: article.link,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final content = await RssService.getContent(
        source: source,
        article: article,
      );
      if (!mounted) return;
      if (content.trim().isEmpty) {
        await AppWebViewPage.openUrl(
          context,
          title: article.title,
          url: article.link,
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _html = _wrapHtml(content, article.title);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _wrapHtml(String body, String title) {
    final styled = widget.source.style.trim();
    return '''
<!DOCTYPE html>
<html><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>$title</title>
<style>
body{font-family:sans-serif;padding:12px;line-height:1.6;word-break:break-word;}
img{max-width:100%;height:auto;}
$styled
</style>
</head><body>$body</body></html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.article.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.article.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => AppWebViewPage.openUrl(
                    context,
                    title: widget.article.title,
                    url: widget.article.link,
                  ),
                  child: const Text('打开原文'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AppWebViewPage(
      title: widget.article.title,
      htmlContent: _html,
      baseUrl: widget.source.loadWithBaseUrl ? widget.article.link : null,
      initialUrl: widget.article.link,
    );
  }
}
