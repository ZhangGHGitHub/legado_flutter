import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/platform/clipboard_port.dart';
import '../../domain/reading_stats.dart';
import '../../services/reading_record_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../widgets/reading_stats_chart.dart';

/// 阅读记录 — 本地统计 + 可选 LegadoRecord Web
class ReadRecordPage extends StatefulWidget {
  const ReadRecordPage({super.key});

  static const recordUrl = 'https://jingshiro.github.io/LegadoRecord/';

  @override
  State<ReadRecordPage> createState() => _ReadRecordPageState();
}

class _ReadRecordPageState extends State<ReadRecordPage> {
  String _range = 'month';
  ReadingStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!ReadingRecordService.isReady) {
      setState(() {
        _loading = false;
        _error = 'Rust 引擎或数据库未就绪';
      });
      return;
    }
    final stats = ReadingRecordService.getStats(_range);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
      if (stats == null) _error = '加载统计失败';
    });
  }

  Future<void> _export(String format) async {
    final text = ReadingRecordService.exportRecords(format);
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出失败或无数据')));
      }
      return;
    }
    await context.read<ClipboardPort>().copyText(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已复制 ${format.toUpperCase()} 到剪贴板')),
      );
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
          PopupMenuButton<String>(
            offset: legadoAppBarPopupOffset(context),
            tooltip: '导出',
            onSelected: _export,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('导出 CSV')),
              PopupMenuItem(value: 'json', child: Text('导出 JSON')),
            ],
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'LegadoRecord 网页版',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? EmptyState(
              icon: Icons.history,
              title: '阅读记录',
              subtitle: _error!,
              actionLabel: '打开 LegadoRecord',
              onAction: _openInBrowser,
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCards(stats: _stats!),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'week', label: Text('近7天')),
                      ButtonSegment(value: 'month', label: Text('近30天')),
                      ButtonSegment(value: 'year', label: Text('近一年')),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) {
                      setState(() => _range = s.first);
                      _loadStats();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('每日字数', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ReadingBarChart(daily: _stats!.daily),
                  const SizedBox(height: 24),
                  Text('阅读热力图', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ReadingHeatmap(daily: _stats!.daily),
                ],
              ),
            ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final ReadingStats stats;

  const _SummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          label: '今日阅读',
          value: ReadingRecordService.formatChars(stats.todayChars),
          sub: ReadingRecordService.formatDuration(stats.todayDurationSeconds),
        ),
        _StatCard(
          label: '本周阅读',
          value: ReadingRecordService.formatChars(stats.weekChars),
        ),
        _StatCard(
          label: '累计阅读',
          value: ReadingRecordService.formatChars(stats.totalChars),
          sub: ReadingRecordService.formatDuration(stats.totalDurationSeconds),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _StatCard({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.titleLarge),
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
