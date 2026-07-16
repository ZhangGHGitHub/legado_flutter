import 'package:flutter/material.dart';

/// 默认键盘辅助键 — 对齐 Jingshiro `defaultData/keyboardAssists.json`。
class KeyboardAssistItem {
  const KeyboardAssistItem({required this.key, required this.value});
  final String key;
  final String value;
}

/// 键盘帮助条 — 对齐 [KeyboardToolPop]：帮助/撤销/重做 + 规则片段芯片。
class KeyboardToolBar extends StatelessWidget {
  const KeyboardToolBar({
    super.key,
    required this.onSendText,
    required this.onUndo,
    required this.onRedo,
    required this.onHelp,
    this.items = defaultAssists,
  });

  final ValueChanged<String> onSendText;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onHelp;
  final List<KeyboardAssistItem> items;

  /// 来自 Jingshiro keyboardAssists.json（type 默认 0 行）。
  static const defaultAssists = <KeyboardAssistItem>[
    KeyboardAssistItem(key: '@css:', value: '@css:'),
    KeyboardAssistItem(key: '<js>', value: '<js></js>'),
    KeyboardAssistItem(key: '{{}}', value: '{{}}'),
    KeyboardAssistItem(key: '##', value: '##'),
    KeyboardAssistItem(key: '&&', value: '&&'),
    KeyboardAssistItem(key: '%%', value: '%%'),
    KeyboardAssistItem(key: '||', value: '||'),
    KeyboardAssistItem(key: '//', value: '//'),
    KeyboardAssistItem(key: '\\', value: '\\'),
    KeyboardAssistItem(key: '\$.', value: '\$.'),
    KeyboardAssistItem(key: '@', value: '@'),
    KeyboardAssistItem(key: ':', value: ':'),
    KeyboardAssistItem(key: 'class', value: 'class'),
    KeyboardAssistItem(key: 'text', value: 'text'),
    KeyboardAssistItem(key: 'href', value: 'href'),
    KeyboardAssistItem(key: 'textNodes', value: 'textNodes'),
    KeyboardAssistItem(key: 'ownText', value: 'ownText'),
    KeyboardAssistItem(key: 'all', value: 'all'),
    KeyboardAssistItem(key: 'html', value: 'html'),
    KeyboardAssistItem(key: '[', value: '['),
    KeyboardAssistItem(key: ']', value: ']'),
    KeyboardAssistItem(key: '<', value: '<'),
    KeyboardAssistItem(key: '>', value: '>'),
    KeyboardAssistItem(key: '#', value: '#'),
    KeyboardAssistItem(key: '!', value: '!'),
    KeyboardAssistItem(key: '.', value: '.'),
    KeyboardAssistItem(key: '+', value: '+'),
    KeyboardAssistItem(key: '-', value: '-'),
    KeyboardAssistItem(key: '*', value: '*'),
    KeyboardAssistItem(key: '/', value: '/'),
    KeyboardAssistItem(key: '=', value: '='),
    KeyboardAssistItem(key: 'useWebView', value: ',{"webView": true}'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHigh;
    return Material(
      color: bg,
      elevation: 2,
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          children: [
            _Chip(
              label: '❓',
              onTap: onHelp,
              emphasized: true,
            ),
            _Chip(label: '↩️', onTap: onUndo),
            _Chip(label: '↪️', onTap: onRedo),
            for (final item in items)
              _Chip(
                label: item.key,
                onTap: () => onSendText(item.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: emphasized
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
