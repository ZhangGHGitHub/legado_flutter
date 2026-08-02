import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/rss/rss_login_port.dart';
import '../../application/rss/rss_notifier.dart';
import '../../application/rss/rss_source_edit_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../../features/sources/source_login_page.dart';
import '../../providers/rss_provider.dart';

/// 订阅源编辑 — 对齐 Jingshiro RssSourceEditActivity 核心字段。
class RssSourceEditPage extends StatelessWidget {
  const RssSourceEditPage({super.key, this.source, this.editor});

  /// `null` 表示新建
  final RssSource? source;

  /// Optional persistence boundary for tests and alternate application shells.
  final RssSourceEditPort? editor;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RssProvider>().controller;
    return riverpod.ProviderScope(
      overrides: [rssSourceControllerProvider.overrideWithValue(controller)],
      child: _RssSourceEditBody(source: source, editor: editor),
    );
  }
}

class _RssSourceEditBody extends riverpod.ConsumerStatefulWidget {
  const _RssSourceEditBody({this.source, this.editor});

  final RssSource? source;
  final RssSourceEditPort? editor;

  @override
  riverpod.ConsumerState<_RssSourceEditBody> createState() =>
      _RssSourceEditBodyState();
}

class _RssSourceEditBodyState extends riverpod.ConsumerState<_RssSourceEditBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _url;
  late final TextEditingController _name;
  late final TextEditingController _icon;
  late final TextEditingController _group;
  late final TextEditingController _comment;
  late final TextEditingController _sortUrl;
  late final TextEditingController _header;
  late final TextEditingController _jsLib;
  late final TextEditingController _loginUrl;
  late final TextEditingController _loginUi;
  late final TextEditingController _ruleArticles;
  late final TextEditingController _ruleNextPage;
  late final TextEditingController _ruleTitle;
  late final TextEditingController _rulePubDate;
  late final TextEditingController _ruleDescription;
  late final TextEditingController _ruleImage;
  late final TextEditingController _ruleLink;
  late final TextEditingController _ruleContent;
  late bool _enabled;
  late bool _singleUrl;
  late bool _enableJs;
  late bool _loadWithBaseUrl;
  late int _articleStyle;
  late int _type;
  var _saving = false;

  bool get _isNew => widget.source == null;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final s = widget.source;
    _url = TextEditingController(text: s?.sourceUrl ?? '');
    _name = TextEditingController(text: s?.sourceName ?? '');
    _icon = TextEditingController(text: s?.sourceIcon ?? '');
    _group = TextEditingController(text: s?.sourceGroup ?? '');
    _comment = TextEditingController(text: s?.sourceComment ?? '');
    _sortUrl = TextEditingController(text: s?.sortUrl ?? '');
    _header = TextEditingController(text: s?.header ?? '');
    _jsLib = TextEditingController(text: s?.jsLib ?? '');
    _loginUrl = TextEditingController(text: s?.loginUrl ?? '');
    _loginUi = TextEditingController(text: s?.loginUi ?? '');
    _ruleArticles = TextEditingController(text: s?.ruleArticles ?? '');
    _ruleNextPage = TextEditingController(text: s?.ruleNextPage ?? '');
    _ruleTitle = TextEditingController(text: s?.ruleTitle ?? '');
    _rulePubDate = TextEditingController(text: s?.rulePubDate ?? '');
    _ruleDescription = TextEditingController(text: s?.ruleDescription ?? '');
    _ruleImage = TextEditingController(text: s?.ruleImage ?? '');
    _ruleLink = TextEditingController(text: s?.ruleLink ?? '');
    _ruleContent = TextEditingController(text: s?.ruleContent ?? '');
    _enabled = s?.enabled ?? true;
    _singleUrl = s?.singleUrl ?? false;
    _enableJs = s?.enableJs ?? true;
    _loadWithBaseUrl = s?.loadWithBaseUrl ?? true;
    _articleStyle = s?.articleStyle ?? 0;
    _type = s?.type ?? 0;
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _url,
      _name,
      _icon,
      _group,
      _comment,
      _sortUrl,
      _header,
      _jsLib,
      _loginUrl,
      _loginUi,
      _ruleArticles,
      _ruleNextPage,
      _ruleTitle,
      _rulePubDate,
      _ruleDescription,
      _ruleImage,
      _ruleLink,
      _ruleContent,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  RssSource _build() {
    final base = Map<String, dynamic>.from(widget.source?.toJson() ?? {});
    base.addAll({
      'sourceUrl': _url.text.trim(),
      'sourceName': _name.text.trim(),
      'sourceIcon': _icon.text.trim(),
      'sourceGroup': _group.text.trim(),
      'sourceComment': _comment.text.trim(),
      'enabled': _enabled,
      'sortUrl': _sortUrl.text.trim(),
      'singleUrl': _singleUrl,
      'header': _header.text.trim(),
      'jsLib': _jsLib.text.trim(),
      'loginUrl': _loginUrl.text.trim().isEmpty ? null : _loginUrl.text.trim(),
      'loginUi': _loginUi.text.trim(),
      'ruleArticles': _ruleArticles.text.trim(),
      'ruleNextPage': _ruleNextPage.text.trim(),
      'ruleTitle': _ruleTitle.text.trim(),
      'rulePubDate': _rulePubDate.text.trim(),
      'ruleDescription': _ruleDescription.text.trim(),
      'ruleImage': _ruleImage.text.trim(),
      'ruleLink': _ruleLink.text.trim(),
      'ruleContent': _ruleContent.text.trim(),
      'enableJs': _enableJs,
      'loadWithBaseUrl': _loadWithBaseUrl,
      'articleStyle': _articleStyle,
      'type': _type,
      'lastUpdateTime': DateTime.now().millisecondsSinceEpoch,
    });
    // fromJson 对 null loginUrl：json['loginUrl']?.toString() — if we put null in map it's fine
    if (_loginUrl.text.trim().isEmpty) {
      base.remove('loginUrl');
    }
    return RssSource.fromJson(base);
  }

  Future<void> _save() async {
    final url = _url.text.trim();
    final name = _name.text.trim();
    if (url.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写源 URL 与名称')));
      return;
    }
    setState(() => _saving = true);
    try {
      final source = _build();
      final editor = widget.editor;
      if (editor != null) {
        await editor.save(source);
      } else {
        await ref.read(rssNotifierProvider.notifier).upsertSource(source);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已保存')));
      Navigator.pop(context, source);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? '新建订阅源' : '编辑订阅源'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: '基础'),
            Tab(text: '列表规则'),
            Tab(text: '正文/其它'),
          ],
        ),
        actions: [
          if (!_isNew &&
              (_loginUrl.text.trim().isNotEmpty ||
                  (widget.source?.loginUrl?.isNotEmpty ?? false)))
            IconButton(
              tooltip: '登录',
              icon: const Icon(Icons.login),
              onPressed: () {
                final draft = _build();
                SourceLoginPage.open(
                  context,
                  context.read<RssLoginPort>().bookSourceForRss(draft),
                );
              },
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field('源 URL', _url, hint: 'https://…'),
              _field('名称', _name),
              _field('图标 URL', _icon),
              _field('分组', _group, hint: '逗号分隔多分组'),
              _field('注释', _comment, maxLines: 2),
              _field(
                '分类 URL (sortUrl)',
                _sortUrl,
                maxLines: 4,
                hint: '名称::url，多行或 && 分隔；可写 @js:',
              ),
              SwitchListTile(
                title: const Text('启用'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              SwitchListTile(
                title: const Text('单 URL（singleUrl）'),
                value: _singleUrl,
                onChanged: (v) => setState(() => _singleUrl = v),
              ),
              ListTile(
                title: const Text('列表样式 articleStyle'),
                subtitle: Text('当前: $_articleStyle'),
                trailing: DropdownButton<int>(
                  value: _articleStyle,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('0 默认')),
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _articleStyle = v);
                  },
                ),
              ),
              ListTile(
                title: const Text('类型 type'),
                subtitle: const Text('0 网页 · 1 图片 · 2 视频'),
                trailing: DropdownButton<int>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('网页')),
                    DropdownMenuItem(value: 1, child: Text('图片')),
                    DropdownMenuItem(value: 2, child: Text('视频')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field('文章列表 ruleArticles', _ruleArticles, maxLines: 3),
              _field('下一页 ruleNextPage', _ruleNextPage, maxLines: 2),
              _field('标题 ruleTitle', _ruleTitle),
              _field('发布时间 rulePubDate', _rulePubDate),
              _field('描述 ruleDescription', _ruleDescription, maxLines: 2),
              _field('封面 ruleImage', _ruleImage),
              _field('链接 ruleLink', _ruleLink),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field('正文 ruleContent', _ruleContent, maxLines: 4),
              _field('请求头 header', _header, maxLines: 3),
              _field('jsLib', _jsLib, maxLines: 3),
              _field('loginUrl', _loginUrl, maxLines: 2),
              _field('loginUi', _loginUi, maxLines: 4),
              SwitchListTile(
                title: const Text('启用 JS（enableJs）'),
                value: _enableJs,
                onChanged: (v) => setState(() => _enableJs = v),
              ),
              SwitchListTile(
                title: const Text('loadWithBaseUrl'),
                value: _loadWithBaseUrl,
                onChanged: (v) => setState(() => _loadWithBaseUrl = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
