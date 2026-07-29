import 'package:flutter/material.dart';

import '../domain/content/replace_rule.dart';
import '../services/replace_service.dart';

typedef ApplyPreviewRules =
    String Function(String text, List<ReplaceRule> rules);

/// 替换规则实时预览面板
class ReplacePreviewPanel extends StatefulWidget {
  const ReplacePreviewPanel({
    super.key,
    required this.rules,
    required this.applyRules,
    this.initialSample,
  });

  final List<ReplaceRule> rules;
  final ApplyPreviewRules applyRules;
  final String? initialSample;

  @override
  State<ReplacePreviewPanel> createState() => ReplacePreviewPanelState();
}

class ReplacePreviewPanelState extends State<ReplacePreviewPanel> {
  late final TextEditingController _inputController;
  String _output = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(
      text: widget.initialSample ?? ReplaceService.defaultSampleText,
    );
    _inputController.addListener(_refreshPreview);
    _refreshPreview();
  }

  @override
  void didUpdateWidget(covariant ReplacePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rules != widget.rules) {
      _refreshPreview();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    try {
      setState(() {
        _output = widget.applyRules(_inputController.text, widget.rules);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _output = '';
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledCount = widget.rules.where((r) => r.isEnabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '已启用 $enabledCount / ${widget.rules.length} 条规则',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _PreviewPane(
                  title: '测试文本',
                  controller: _inputController,
                  readOnly: false,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _PreviewPane(
                  title: '替换结果',
                  text: _error ?? _output,
                  readOnly: true,
                  error: _error != null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.title,
    this.controller,
    this.text,
    required this.readOnly,
    this.error = false,
  });

  final String title;
  final TextEditingController? controller;
  final String? text;
  final bool readOnly;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: error
                      ? theme.colorScheme.error
                      : theme.colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              child: readOnly
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        text ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: error ? theme.colorScheme.error : null,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: '输入或粘贴待净化正文…',
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
