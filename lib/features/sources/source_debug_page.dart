import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../application/source_management/source_notifier.dart';
import '../../application/sources/source_debug_formatter_port.dart';
import '../../domain/ports/book_source_debug_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import '../../widgets/source_debug_panel.dart';
import '../../widgets/source_validation_sheet.dart';

/// 书源调试 — 对齐 Jingshiro [BookSourceDebugActivity] / [activity_source_debug.xml]
///
/// 从编辑页菜单「调试源」进入（保存后打开）。
class SourceDebugPage extends riverpod.ConsumerStatefulWidget {
  final BookSource source;
  final BookSourceDebugPort debugPort;

  const SourceDebugPage({
    super.key,
    required this.source,
    required this.debugPort,
  });

  static Future<void> open(BuildContext context, BookSource source) {
    final debugPort = context.read<BookSourceDebugPort>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SourceDebugPage(source: source, debugPort: debugPort),
      ),
    );
  }

  @override
  riverpod.ConsumerState<SourceDebugPage> createState() =>
      _SourceDebugPageState();
}

class _SourceDebugPageState extends riverpod.ConsumerState<SourceDebugPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchKeyword = '';
  final _searchCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _chapterUrlCtrl = TextEditingController();
  String _debugLog = '';
  bool _isDebugLoading = false;
  bool _isValidating = false;
  String? _rawResponse;
  late final BookSourceDebugPort _debugPort;
  BookSourceDebugSnapshot? _lastDebugResult;
  List<BookSourceDebugItem> _testChapters = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _debugPort = widget.debugPort;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _urlCtrl.dispose();
    _chapterUrlCtrl.dispose();
    super.dispose();
  }

  void _appendLog(String line) {
    setState(() => _debugLog += '$line\n');
  }

  Future<void> _runSearchDebug() async {
    if (_searchKeyword.isEmpty) return;
    setState(() {
      _isDebugLoading = true;
      _debugLog = '';
      _lastDebugResult = null;
    });
    try {
      if (!_debugPort.isAvailable) {
        _appendLog('❌ Rust 引擎不可用，请先编译 legado_engine');
        return;
      }
      _appendLog('🔍 搜索关键词: "$_searchKeyword"');
      _appendLog('📡 书源: ${widget.source.bookSourceName}');
      _appendLog('');
      final result = await _debugPort.debugSearch(
        widget.source,
        _searchKeyword,
      );
      setState(() {
        _lastDebugResult = result;
        _debugLog = context.read<SourceDebugFormatterPort>().format(result);
        _rawResponse = result.responseBodyPreview.isNotEmpty
            ? result.responseBodyPreview
            : null;
      });
    } catch (e) {
      _appendLog('❌ 搜索出错: $e');
    } finally {
      if (mounted) setState(() => _isDebugLoading = false);
    }
  }

  Future<void> _runChapterDebug() async {
    final url = _chapterUrlCtrl.text.trim();
    if (url.isEmpty) {
      _appendLog('⚠️ 请先输入书籍 URL');
      return;
    }
    setState(() {
      _isDebugLoading = true;
      _testChapters = [];
      _debugLog = '';
      _lastDebugResult = null;
    });
    try {
      if (!_debugPort.isAvailable) {
        _appendLog('❌ Rust 引擎不可用');
        return;
      }
      _appendLog('📖 获取章节列表...');
      _appendLog('URL: $url');
      final result = await _debugPort.debugToc(widget.source, url);
      setState(() {
        _lastDebugResult = result;
        _testChapters = result.results;
        _debugLog = context.read<SourceDebugFormatterPort>().format(result);
      });
    } catch (e) {
      _appendLog('❌ 出错: $e');
    } finally {
      if (mounted) setState(() => _isDebugLoading = false);
    }
  }

  Future<void> _runUrlTest() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _isDebugLoading = true;
      _debugLog = '';
      _rawResponse = null;
      _lastDebugResult = null;
    });
    try {
      if (!_debugPort.isAvailable) {
        _appendLog('❌ Rust 引擎不可用');
        return;
      }
      _appendLog('📡 请求: $url');
      final body = await _debugPort.httpFetch(
        url,
        referer: widget.source.bookSourceUrl,
        source: widget.source,
      );
      _appendLog('✅ 完成');
      _appendLog('📊 大小: ${body.length} chars');
      _appendLog(
        '🧪 内容预览: ${body.substring(0, body.length > 200 ? 200 : body.length)}',
      );
      setState(() => _rawResponse = body);
    } catch (e) {
      _appendLog('❌ 请求失败: $e');
    } finally {
      if (mounted) setState(() => _isDebugLoading = false);
    }
  }

  Future<void> _runFullValidation() async {
    setState(() => _isValidating = true);
    try {
      final result = await ref
          .read(sourceNotifierProvider.notifier)
          .validateSource(
            widget.source,
            keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
          );
      if (!mounted || result == null) return;
      await SourceValidationSheet.show(
        context,
        sourceName: widget.source.bookSourceName,
        result: result,
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('调试: ${widget.source.bookSourceName}'),
        actions: [
          IconButton(
            icon: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            tooltip: '一键校验',
            onPressed: _isValidating ? null : _runFullValidation,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: '搜索', icon: Icon(Icons.search, size: 16)),
            Tab(text: '章节', icon: Icon(Icons.list_alt, size: 16)),
            Tab(text: 'URL测试', icon: Icon(Icons.link, size: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(theme),
                _buildChapterTab(theme),
                _buildUrlTab(theme),
              ],
            ),
          ),
          SourceDebugPanel(result: _lastDebugResult),
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  _debugLog.isEmpty ? '操作日志会显示在这里...' : _debugLog,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清空日志'),
                    onPressed: () => setState(() => _debugLog = ''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('保存日志'),
                    onPressed: () {
                      if (_debugLog.isEmpty) return;
                      final tempFile =
                          '${widget.source.bookSourceName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}_debug.txt';
                      try {
                        File(tempFile).writeAsStringSync(_debugLog);
                        _appendLog('\n📋 日志已保存到: $tempFile');
                      } catch (_) {}
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: '输入搜索关键词...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) => _searchKeyword = v,
                  onSubmitted: (_) => _runSearchDebug(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _isDebugLoading ? null : _runSearchDebug,
                child: _isDebugLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('测试搜索'),
              ),
            ],
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Widget _buildChapterTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              TextField(
                controller: _chapterUrlCtrl,
                decoration: const InputDecoration(
                  hintText: '输入书籍详情/目录页 URL...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: _isDebugLoading ? null : _runChapterDebug,
                  child: const Text('测试章节列表'),
                ),
              ),
            ],
          ),
        ),
        if (_testChapters.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _testChapters.length > 20 ? 20 : _testChapters.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                leading: Text('${i + 1}'),
                title: Text(_testChapters[i].name, maxLines: 1),
                subtitle: Text(
                  _testChapters[i].bookUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  Widget _buildUrlTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    hintText: '输入任意 URL 测试...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _runUrlTest(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _isDebugLoading ? null : _runUrlTest,
                child: const Text('请求'),
              ),
            ],
          ),
        ),
        if (_rawResponse != null)
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: SelectableText(
                  _rawResponse!.length > 5000
                      ? '${_rawResponse!.substring(0, 5000)}\n\n... (truncated)'
                      : _rawResponse!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
