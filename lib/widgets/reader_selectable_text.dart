import 'package:flutter/material.dart';

/// 阅读器可选文本 — 长按菜单含「写想法」
class ReaderSelectableText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final void Function(String selectedText) onWriteNote;

  const ReaderSelectableText({
    super.key,
    required this.text,
    required this.style,
    required this.onWriteNote,
  });

  String _selectedText(EditableTextState state) {
    final value = state.textEditingValue;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) return '';
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(0, value.text.length);
    if (start >= end) return '';
    return value.text.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      contextMenuBuilder: (ctx, editableTextState) {
        final selected = _selectedText(editableTextState);
        final items = <ContextMenuButtonItem>[
          ...editableTextState.contextMenuButtonItems,
          ContextMenuButtonItem(
            label: '写想法',
            onPressed: selected.isEmpty
                ? () {}
                : () {
                    ContextMenuController.removeAny();
                    onWriteNote(selected);
                  },
          ),
        ];
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }
}
