import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 下载选项结果（对齐 `dialog_download_choice.xml`）
enum DownloadRangeKind {
  /// 全部章节
  all,

  /// 仅未缓存
  notCached,

  /// 从当前章到书末
  fromCurrent,

  /// 从当前章起后 N 章（含当前）
  nextN,
}

class DownloadChoiceResult {
  final DownloadRangeKind range;
  final int nextCount;
  final int concurrency;

  const DownloadChoiceResult({
    required this.range,
    this.nextCount = 50,
    this.concurrency = 1,
  });
}

/// 离线缓存范围选择 — 对齐 Jingshiro `dialog_download_choice`
class DownloadChoiceDialog extends StatefulWidget {
  final int currentChapterIndex;
  final int totalChapters;
  final int cachedCount;

  const DownloadChoiceDialog({
    super.key,
    required this.currentChapterIndex,
    required this.totalChapters,
    this.cachedCount = 0,
  });

  static Future<DownloadChoiceResult?> show(
    BuildContext context, {
    required int currentChapterIndex,
    required int totalChapters,
    int cachedCount = 0,
  }) {
    return showDialog<DownloadChoiceResult>(
      context: context,
      builder: (_) => DownloadChoiceDialog(
        currentChapterIndex: currentChapterIndex,
        totalChapters: totalChapters,
        cachedCount: cachedCount,
      ),
    );
  }

  @override
  State<DownloadChoiceDialog> createState() => _DownloadChoiceDialogState();
}

class _DownloadChoiceDialogState extends State<DownloadChoiceDialog> {
  static const _kConcurrency = 'download_choice_concurrency';
  static const _kNextN = 'download_choice_next_n';

  DownloadRangeKind _range = DownloadRangeKind.notCached;
  late final TextEditingController _nextNCtrl;
  int _concurrency = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nextNCtrl = TextEditingController(text: '50');
    _loadPrefs();
  }

  @override
  void dispose() {
    _nextNCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _concurrency = (p.getInt(_kConcurrency) ?? 1).clamp(1, 8);
      final n = (p.getInt(_kNextN) ?? 50).clamp(1, 9999);
      _nextNCtrl.text = '$n';
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    final nextN = int.tryParse(_nextNCtrl.text.trim()) ?? 50;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kConcurrency, _concurrency);
    await p.setInt(_kNextN, nextN.clamp(1, 9999));
    if (!mounted) return;
    Navigator.pop(
      context,
      DownloadChoiceResult(
        range: _range,
        nextCount: nextN.clamp(1, 9999),
        concurrency: _concurrency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uncached = (widget.totalChapters - widget.cachedCount).clamp(
      0,
      widget.totalChapters,
    );

    return AlertDialog(
      title: const Text('下载选项'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '共 ${widget.totalChapters} 章 · 已缓存 ${widget.cachedCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<DownloadRangeKind>(
                    groupValue: _range,
                    onChanged: (v) {
                      if (v != null) setState(() => _range = v);
                    },
                    child: Column(
                      children: [
                        RadioListTile<DownloadRangeKind>(
                          value: DownloadRangeKind.notCached,
                          title: const Text(
                            '下载未缓存章节',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '约 $uncached 章',
                            style: const TextStyle(fontSize: 12),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<DownloadRangeKind>(
                          value: DownloadRangeKind.all,
                          title: const Text(
                            '下载全部章节',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '共 ${widget.totalChapters} 章',
                            style: const TextStyle(fontSize: 12),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<DownloadRangeKind>(
                          value: DownloadRangeKind.fromCurrent,
                          title: const Text(
                            '从当前章节下载到结尾',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '第 ${widget.currentChapterIndex + 1} 章起',
                            style: const TextStyle(fontSize: 12),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<DownloadRangeKind>(
                          value: DownloadRangeKind.nextN,
                          title: const Text(
                            '从当前章节下载',
                            style: TextStyle(fontSize: 14),
                          ),
                          secondary: SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _nextNCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: '章',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Text('并发数', style: theme.textTheme.titleSmall),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _concurrency.toDouble(),
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '$_concurrency',
                          onChanged: (v) =>
                              setState(() => _concurrency = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text('$_concurrency', textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                  Text(
                    '格式：纯文本（HTML 导出尚未接入）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          child: const Text('下载'),
        ),
      ],
    );
  }
}
