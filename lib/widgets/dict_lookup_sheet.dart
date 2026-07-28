import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../models/dict_rule.dart';
import '../services/dict_rule_prefs.dart';
import '../services/dict_rule_tester.dart';

typedef DictRulesLoader = Future<List<DictRule>> Function();
typedef DictRuleQuery = Future<String> Function(DictRule rule, String word);
typedef DictRuleButtonHandler =
    Future<void> Function(DictRule rule, String name, String click);

/// 选中文本词典结果面板，对齐原版 DictDialog 的启用规则和 Tab 行为。
class DictLookupSheet extends StatefulWidget {
  final String word;
  final DictRulesLoader loadRules;
  final DictRuleQuery queryRule;
  final DictRuleButtonHandler? onButtonClick;

  const DictLookupSheet({
    super.key,
    required this.word,
    this.loadRules = DictRulePrefs.load,
    this.queryRule = DictRuleTester.test,
    this.onButtonClick,
  });

  @override
  State<DictLookupSheet> createState() => _DictLookupSheetState();
}

class _DictLookupSheetState extends State<DictLookupSheet>
    with SingleTickerProviderStateMixin {
  List<DictRule> _rules = const [];
  TabController? _tabs;
  bool _loadingRules = true;
  String? _rulesError;
  int _queryGeneration = 0;
  final Map<String, _DictResult> _results = {};

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final rules =
          (await widget.loadRules()).where((rule) => rule.enabled).toList()
            ..sort((a, b) => a.sortNumber.compareTo(b.sortNumber));
      if (!mounted) return;
      if (rules.isEmpty) {
        setState(() {
          _rules = const [];
          _loadingRules = false;
        });
        return;
      }
      final controller = TabController(length: rules.length, vsync: this);
      controller.addListener(_onTabChanged);
      setState(() {
        _rules = rules;
        _tabs = controller;
        _loadingRules = false;
      });
      unawaited(_query(0));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRules = false;
        _rulesError = _errorText(error);
      });
    }
  }

  void _onTabChanged() {
    final controller = _tabs;
    if (controller == null || controller.indexIsChanging) return;
    unawaited(_query(controller.index));
  }

  Future<void> _query(int index) async {
    if (index < 0 || index >= _rules.length) return;
    final rule = _rules[index];
    final generation = ++_queryGeneration;
    setState(() => _results[rule.name] = const _DictResult.loading());
    try {
      final value = await widget.queryRule(rule, widget.word);
      if (!mounted || generation != _queryGeneration) return;
      setState(() => _results[rule.name] = _DictResult.success(value));
    } catch (error) {
      if (!mounted || generation != _queryGeneration) return;
      setState(
        () => _results[rule.name] = _DictResult.failure(_errorText(error)),
      );
    }
  }

  static String _errorText(Object error) {
    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) return text.substring(11);
    return text.isEmpty ? '查询失败' : text;
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChanged);
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: _loadingRules
              ? const Center(child: CircularProgressIndicator())
              : _rulesError != null
              ? _Message(text: '词典加载失败：$_rulesError')
              : _rules.isEmpty
              ? const _Message(text: '暂无启用的词典规则')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '词典：${widget.word}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: tabs,
                      isScrollable: _rules.length > 4,
                      tabs: [for (final rule in _rules) Tab(text: rule.name)],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: tabs,
                        children: [
                          for (final rule in _rules) _buildResult(rule),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResult(DictRule rule) {
    final result = _results[rule.name];
    if (result == null || result.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (result.error != null) {
      return SingleChildScrollView(
        child: SelectableText('查询失败：${result.error}'),
      );
    }
    final value = result.value?.trim() ?? '';
    if (value.isEmpty) return const _Message(text: '暂无结果');
    return DictResultContent(
      content: value,
      rule: rule,
      onButtonClick: widget.onButtonClick,
    );
  }
}

/// 将原版 DictDialog 的 HTML/Markdown 结果映射到 Flutter 控件。
///
/// 词典规则的查询仍由 [DictRuleTester] 负责；此组件只负责展示结果，
/// 不参与正文清洗、断行或分页。
class DictResultContent extends StatefulWidget {
  final String content;
  final DictRule rule;
  final DictRuleButtonHandler? onButtonClick;

  const DictResultContent({
    super.key,
    required this.content,
    required this.rule,
    this.onButtonClick,
  });

  @override
  State<DictResultContent> createState() => _DictResultContentState();
}

class _DictResultContentState extends State<DictResultContent> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content.trimLeft();
    if (content.startsWith('<md>')) {
      final end = content.lastIndexOf('<');
      final markdown = end > 4 ? content.substring(4, end) : content;
      return _buildMarkdown(context, markdown);
    }
    if (!RegExp(r'<[a-zA-Z][^>]*>').hasMatch(content)) {
      return SingleChildScrollView(child: SelectableText(widget.content));
    }
    final fragment = html_parser.parseFragment(content);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _renderNodes(context, fragment.nodes),
      ),
    );
  }

  Widget _buildMarkdown(BuildContext context, String markdown) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (final rawLine in markdown.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }
      final heading = RegExp(r'^#{1,6}\s+').firstMatch(line);
      final bullet = RegExp(r'^\s*[-*+]\s+').firstMatch(line);
      final text = heading != null
          ? line.substring(heading.end)
          : bullet != null
          ? '• ${line.substring(bullet.end)}'
          : line;
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(
              style: heading == null
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              children: _inlineMarkdownSpans(text, theme),
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(child: Column(children: children));
  }

  List<InlineSpan> _inlineMarkdownSpans(String text, ThemeData theme) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(!?)\[([^]]*)\]\(([^)]+)\)|\*\*([^*]+)\*\*');
    var offset = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > offset) {
        spans.add(TextSpan(text: text.substring(offset, match.start)));
      }
      final image = match.group(1) == '!';
      final label = match.group(2);
      final target = match.group(3);
      final bold = match.group(4);
      if (image && target != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Image.network(
                target,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Text(label ?? target),
              ),
            ),
          ),
        );
      } else if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: label ?? target ?? '',
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
      offset = match.end;
    }
    if (offset < text.length) spans.add(TextSpan(text: text.substring(offset)));
    if (spans.isEmpty) spans.add(TextSpan(text: text));
    return spans;
  }

  List<Widget> _renderNodes(BuildContext context, List<dom.Node> nodes) {
    final output = <Widget>[];
    for (final node in nodes) {
      if (node is dom.Text) {
        if (node.data.trim().isNotEmpty) {
          output.add(SelectableText(node.data));
        }
        continue;
      }
      if (node is! dom.Element) continue;
      final tag = node.localName?.toLowerCase() ?? '';
      if (tag == 'img') {
        final src = node.attributes['src']?.trim();
        if (src != null && src.isNotEmpty) {
          output.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Image.network(
                src,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    SelectableText(src),
              ),
            ),
          );
        }
        continue;
      }
      if (tag == 'button') {
        final name = node.attributes['name'] ?? 'button';
        final click =
            node.attributes['onclick'] ??
            node.attributes['data-click'] ??
            node.text;
        output.add(
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onButtonClick == null
                  ? null
                  : () => widget.onButtonClick!(widget.rule, name, click),
              child: Text(node.text.trim().isEmpty ? name : node.text.trim()),
            ),
          ),
        );
        continue;
      }
      if (_isBlockTag(tag)) {
        final spans = _inlineHtmlSpans(context, node.nodes);
        if (spans.isNotEmpty) {
          output.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SelectableText.rich(TextSpan(children: spans)),
            ),
          );
        }
        continue;
      }
      output.addAll(_renderNodes(context, node.nodes));
    }
    return output;
  }

  List<InlineSpan> _inlineHtmlSpans(
    BuildContext context,
    List<dom.Node> nodes, {
    TextStyle? style,
  }) {
    final theme = Theme.of(context);
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node is dom.Text) {
        spans.add(TextSpan(text: node.data, style: style));
        continue;
      }
      if (node is! dom.Element) continue;
      final tag = node.localName?.toLowerCase() ?? '';
      if (tag == 'br') {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      if (tag == 'img') {
        final src = node.attributes['src'];
        if (src != null && src.isNotEmpty) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image.network(
                src,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(src),
              ),
            ),
          );
        }
        continue;
      }
      final nextStyle =
          style?.merge(_styleForTag(tag, theme)) ?? _styleForTag(tag, theme);
      if (tag == 'a') {
        final href = node.attributes['href'];
        final recognizer = TapGestureRecognizer();
        if (href != null && href.isNotEmpty) {
          recognizer.onTap = () =>
              launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            style: nextStyle.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: recognizer,
            children: _inlineHtmlSpans(context, node.nodes, style: nextStyle),
          ),
        );
      } else {
        spans.addAll(_inlineHtmlSpans(context, node.nodes, style: nextStyle));
      }
    }
    return spans;
  }

  static bool _isBlockTag(String tag) => {
    'body',
    'div',
    'p',
    'section',
    'article',
    'header',
    'footer',
    'li',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'pre',
  }.contains(tag);

  static TextStyle _styleForTag(String tag, ThemeData theme) {
    switch (tag) {
      case 'b':
      case 'strong':
        return const TextStyle(fontWeight: FontWeight.bold);
      case 'i':
      case 'em':
        return const TextStyle(fontStyle: FontStyle.italic);
      case 'h1':
        return theme.textTheme.headlineSmall ?? const TextStyle(fontSize: 24);
      case 'h2':
        return theme.textTheme.titleLarge ?? const TextStyle(fontSize: 20);
      case 'h3':
        return theme.textTheme.titleMedium ?? const TextStyle(fontSize: 18);
      case 'code':
        return const TextStyle(fontFamily: 'monospace');
      default:
        return const TextStyle();
    }
  }
}

class _DictResult {
  final bool loading;
  final String? value;
  final String? error;

  const _DictResult.loading() : loading = true, value = null, error = null;
  const _DictResult.success(this.value) : loading = false, error = null;
  const _DictResult.failure(this.error) : loading = false, value = null;
}

class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, textAlign: TextAlign.center));
  }
}

Future<void> showDictLookupSheet(BuildContext context, String word) async {
  final value = word.trim();
  if (value.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法查询空文本')));
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DictLookupSheet(word: value),
  );
}
