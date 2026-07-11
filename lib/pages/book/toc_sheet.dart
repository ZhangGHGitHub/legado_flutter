import 'package:flutter/material.dart';

import '../../models/chapter.dart';

/// 章节目录 BottomSheet — 复用 BookInfo / Reader
class TocSheet extends StatefulWidget {
  final List<Chapter> chapters;
  final String? currentChapter;
  final ValueChanged<Chapter> onChapterTap;

  const TocSheet({
    super.key,
    required this.chapters,
    this.currentChapter,
    required this.onChapterTap,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Chapter> chapters,
    String? currentChapter,
    required ValueChanged<Chapter> onChapterTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => TocSheet(
          chapters: chapters,
          currentChapter: currentChapter,
          onChapterTap: onChapterTap,
        ),
      ),
    );
  }

  @override
  State<TocSheet> createState() => _TocSheetState();
}

class _TocSheetState extends State<TocSheet> {
  bool _reversed = false;

  List<Chapter> get _displayChapters =>
      _reversed ? widget.chapters.reversed.toList() : widget.chapters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              const Text(
                '章节目录',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _reversed = !_reversed),
                icon: Icon(_reversed ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                label: Text(_reversed ? '正序' : '倒序', style: const TextStyle(fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '共 ${widget.chapters.length} 章',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: _displayChapters.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
            itemBuilder: (_, i) {
              final chapter = _displayChapters[i];
              final origIndex = widget.chapters.indexOf(chapter);
              final isCurrent = chapter.title == widget.currentChapter;
              return ListTile(
                dense: true,
                selected: isCurrent,
                leading: Text(
                  '${origIndex + 1}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                title: Text(
                  chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: chapter.isDownloaded
                    ? Icon(Icons.check_circle, size: 16, color: Colors.green[400])
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  widget.onChapterTap(chapter);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
