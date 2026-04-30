import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_source.dart';
import '../../providers/library_provider.dart';
import '../../services/book_source_service.dart';

/// 书源规则编辑器 + 调试面板
class SourceEditorPage extends StatefulWidget {
  final BookSource source;

  const SourceEditorPage({super.key, required this.source});

  @override
  State<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _SourceEditorPageState extends State<SourceEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _jsonController;
  String? _jsonError;
  bool _isSaving = false;

  // 调试状态
  String _searchKeyword = '';
  final _searchCtrl = TextEditingController();
  String _debugLog = '';
  bool _isDebugLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _jsonController = TextEditingController(
      text: _formatJson(widget.source.rawSourceJson.isNotEmpty
          ? widget.source.rawSourceJson
          : _buildDefaultJson()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw;
    }
  }

  String _buildDefaultJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'bookSourceName': widget.source.bookSourceName,
      'bookSourceUrl': widget.source.bookSourceUrl,
      'bookSourceGroup': widget.source.bookSourceGroup,
      'ruleSearchUrl': widget.source.ruleSearchUrl,
      'ruleSearchList': widget.source.ruleSearchList,
      'ruleSearchName': widget.source.ruleSearchName,
      'ruleContent': widget.source.ruleContent,
      'ruleChapterList': widget.source.ruleChapterList,
    });
  }

  Future<void> _saveJson() async {
    setState(() {
      _isSaving = true;
      _jsonError = null;
    });

    try {
      // 验证 JSON 格式
      final jsonStr = _jsonController.text;
      jsonDecode(jsonStr); // 格式校验

      // 从 JSON 重建 BookSource
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final updated = BookSource(
        bookSourceUrl: parsed['bookSourceUrl'] as String? ?? widget.source.bookSourceUrl,
        bookSourceName: parsed['bookSourceName'] as String? ?? widget.source.bookSourceName,
        bookSourceGroup: parsed['bookSourceGroup'] as String? ?? widget.source.bookSourceGroup,
        enabled: widget.source.enabled,
        rawSourceJson: jsonStr,
        ruleSearchUrl: parsed['ruleSearchUrl'] as String? ?? '',
        ruleSearchList: parsed['ruleSearchList'] as String? ?? '',
        ruleSearchName: parsed['ruleSearchName'] as String? ?? '',
        ruleSearchAuthor: parsed['ruleSearchAuthor'] as String? ?? '',
        ruleSearchCoverUrl: parsed['ruleSearchCoverUrl'] as String? ?? '',
        ruleSearchKind: parsed['ruleSearchKind'] as String? ?? '',
        ruleSearchNote: parsed['ruleSearchNote'] as String? ?? '',
        ruleContent: parsed['ruleContent'] as String? ?? '',
        ruleContentUrl: parsed['ruleContentUrl'] as String? ?? '',
        ruleContentRemove: parsed['ruleContentRemove'] as String? ?? '',
        ruleChapterList: parsed['ruleChapterList'] as String? ?? '',
        ruleChapterName: parsed['ruleChapterName'] as String? ?? '',
        ruleChapterUrl: parsed['ruleChapterUrl'] as String? ?? '',
        ruleBookName: parsed['ruleBookName'] as String? ?? '',
        ruleBookAuthor: parsed['ruleBookAuthor'] as String? ?? '',
        ruleBookCoverUrl: parsed['ruleBookCoverUrl'] as String? ?? '',
      );

      await context.read<LibraryProvider>().updateSource(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('书源已保存')),
        );
      }
    } catch (e) {
      setState(() => _jsonError = 'JSON 格式错误: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _runSearchDebug() async {
    if (_searchKeyword.isEmpty) return;
    setState(() {
      _isDebugLoading = true;
      _debugLog = '';
    });

    try {
      final service = BookSourceService();
      _appendLog('🔍 搜索关键词: "$_searchKeyword"');
      _appendLog('📡 书源: ${widget.source.bookSourceName}');
      _appendLog('');

      // 获取原始响应
      _appendLog('📡 请求URL: ${widget.source.ruleSearchUrl.replaceAll('{{key}}', _searchKeyword)}');
      final results = await service.search(widget.source, _searchKeyword);
      
      _appendLog('✅ 搜索完成');
      _appendLog('📊 结果数量: ${results.length}');
      _appendLog('');
      
      if (results.isEmpty) {
        _appendLog('⚠️ 无搜索结果');
        _appendLog('  可能原因:');
        _appendLog('  - 书源规则不匹配');
        _appendLog('  - 搜索结果为空');
        _appendLog('  - 网络请求失败');
      } else {
        for (int i = 0; i < results.length && i < 10; i++) {
          final book = results[i];
          _appendLog('── 结果 ${i + 1} ──');
          _appendLog('  书名: ${book['name'] ?? '未知'}');
          _appendLog('  作者: ${book['author'] ?? '未知'}');
          _appendLog('  链接: ${book['url'] ?? '未知'}');
          _appendLog('  封面: ${book['coverUrl'] ?? '无'}');
          _appendLog('');
        }
        if (results.length > 10) {
          _appendLog('  ... 还有 ${results.length - 10} 个结果');
        }
      }
    } catch (e) {
      _appendLog('❌ 搜索出错: $e');
      _appendLog('');
      _appendLog('错误类型: ${e.runtimeType}');
      _appendLog('请检查书源规则是否正确');
    } finally {
      if (mounted) setState(() => _isDebugLoading = false);
    }
  }

  void _appendLog(String line) {
    setState(() => _debugLog += '$line\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑: ${widget.source.bookSourceName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '规则编辑', icon: Icon(Icons.code)),
            Tab(text: '调试面板', icon: Icon(Icons.bug_report)),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveJson,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('保存'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditorTab(theme),
          _buildDebugTab(theme),
        ],
      ),
    );
  }

  Widget _buildEditorTab(ThemeData theme) {
    return Column(
      children: [
        if (_jsonError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_jsonError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ),
          ),
        Expanded(
          child: TextField(
            controller: _jsonController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: '编辑书源 JSON...',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugTab(ThemeData theme) {
    return Column(
      children: [
        // 搜索测试输入
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('测试搜索'),
              ),
            ],
          ),
        ),
        // 调试日志
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                _debugLog.isEmpty ? '输入关键词后点击「测试搜索」开始调试...' : _debugLog,
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
        // 底部操作
        Container(
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
                  label: const Text('复制日志'),
                  onPressed: () {
                    if (_debugLog.isNotEmpty) {
                      // 保存到剪贴板文件, 防止 Windows 剪贴板 API 问题
                      final tempFile =
                          '${widget.source.bookSourceName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}_debug.txt';
                      try {
                        File(tempFile).writeAsStringSync(_debugLog);
                        _appendLog('\n📋 日志已保存到: $tempFile');
                      } catch (_) {
                        // 忽略写入失败
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
