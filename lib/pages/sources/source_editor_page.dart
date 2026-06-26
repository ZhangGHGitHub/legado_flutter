import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../models/book_source.dart';
import '../../providers/source_provider.dart';
import '../../services/book_source_service.dart';
import '../../models/book.dart';
import '../../models/chapter.dart';

/// 书源规则编辑器 + 调试面板（增强版）
class SourceEditorPage extends StatefulWidget {
  final BookSource source;

  const SourceEditorPage({super.key, required this.source});

  @override
  State<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _SourceEditorPageState extends State<SourceEditorPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _debugTabController;
  late TextEditingController _jsonController;
  String? _jsonError;
  bool _isSaving = false;

  // 调试状态
  String _searchKeyword = '';
  final _searchCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _chapterUrlCtrl = TextEditingController();
  String _debugLog = '';
  bool _isDebugLoading = false;
  String? _rawResponse; // 原始响应预览

  // 章节测试
  List<Chapter> _testChapters = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _debugTabController = TabController(length: 3, vsync: this);
    _jsonController = TextEditingController(
      text: _formatJson(widget.source.rawSourceJson.isNotEmpty
          ? widget.source.rawSourceJson
          : _buildDefaultJson()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debugTabController.dispose();
    _jsonController.dispose();
    _searchCtrl.dispose();
    _urlCtrl.dispose();
    _chapterUrlCtrl.dispose();
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

      await context.read<SourceProvider>().updateSource(updated);
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
          _buildEnhancedDebugTab(theme),
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

  /// Enhanced debug tab with sub-tabs for search, chapters, content, and URL testing
  Widget _buildEnhancedDebugTab(ThemeData theme) {
    return Column(
      children: [
        // Debug sub-tabs
        Container(
          color: theme.colorScheme.surfaceContainerLow,
          child: TabBar(
            controller: _debugTabController,
            labelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: '搜索', icon: Icon(Icons.search, size: 16)),
              Tab(text: '章节', icon: Icon(Icons.list_alt, size: 16)),
              Tab(text: 'URL测试', icon: Icon(Icons.link, size: 16)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _debugTabController,
            children: [
              _buildSearchDebugTab(theme),
              _buildChapterDebugTab(theme),
              _buildUrlDebugTab(theme),
            ],
          ),
        ),
        // Log output area
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
        // Bottom action bar
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
                  label: const Text('保存日志'),
                  onPressed: () {
                    if (_debugLog.isNotEmpty) {
                      final tempFile =
                          '${widget.source.bookSourceName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}_debug.txt';
                      try {
                        File(tempFile).writeAsStringSync(_debugLog);
                        _appendLog('\n📋 日志已保存到: $tempFile');
                      } catch (_) {}
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

  /// Search debug tab
  Widget _buildSearchDebugTab(ThemeData theme) {
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('测试搜索'),
              ),
            ],
          ),
        ),
        // Rule info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('搜索规则', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[800])),
              const SizedBox(height: 2),
              Text('URL: ${widget.source.ruleSearchUrl}', style: TextStyle(fontSize: 10, color: Colors.blue[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('列表: ${widget.source.ruleSearchList}', style: TextStyle(fontSize: 10, color: Colors.blue[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('书名: ${widget.source.ruleSearchName}', style: TextStyle(fontSize: 10, color: Colors.blue[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  /// Chapter debug tab
  Widget _buildChapterDebugTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _chapterUrlCtrl,
                decoration: const InputDecoration(
                  hintText: '输入书籍详情/目录页 URL...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _isDebugLoading ? null : _runChapterDebug,
                    child: const Text('测试章节列表'),
                  ),
                  const SizedBox(width: 8),
                  if (_testChapters.isNotEmpty)
                    Text('${_testChapters.length} 章', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        // Rule info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: Colors.teal.shade50,
          child: Text(
            '目录规则: ${widget.source.ruleChapterList}',
            style: TextStyle(fontSize: 10, color: Colors.teal[700]),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ),
        // Chapter list preview
        if (_testChapters.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _testChapters.length > 20 ? 20 : _testChapters.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                leading: Text('${i + 1}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                title: Text(_testChapters[i].title, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_testChapters[i].url, style: TextStyle(fontSize: 10, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  /// URL test tab - test any URL with this source
  Widget _buildUrlDebugTab(ThemeData theme) {
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        // Raw response (truncated)
        if (_rawResponse != null)
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: SelectableText(
                  _rawResponse!.length > 5000
                      ? '${_rawResponse!.substring(0, 5000)}\n\n... (truncated, ${_rawResponse!.length} chars total)'
                      : _rawResponse!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4, color: Color(0xFFAAAAAA)),
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }

  // ── Debug operations ──

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
    });

    try {
      final service = BookSourceService();
      final book = Book(
        id: 'test_book',
        name: '测试书籍',
        sourceUrl: url,
        bookSourceUrl: widget.source.bookSourceUrl,
      );
      
      _appendLog('📖 获取章节列表...');
      _appendLog('URL: $url');
      final chapters = await service.getChapters(book, source: widget.source);
      
      setState(() => _testChapters = chapters);
      _appendLog('✅ 成功: ${chapters.length} 章');
      for (int i = 0; i < chapters.length && i < 5; i++) {
        _appendLog('  ${i + 1}. ${chapters[i].title}');
      }
      if (chapters.length > 5) {
        _appendLog('  ... 还有 ${chapters.length - 5} 章');
      }
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
    });

    try {
      // Use a direct Dio client for URL testing
      _appendLog('📡 请求: $url');
      
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept-Encoding': 'gzip, deflate',
        },
      ));
      // Note: SSL certificate bypass not available in this context

      final response = await dio.get(url,
        options: Options(responseType: ResponseType.bytes),
      );

      List<int> bytes = response.data as List<int>? ?? [];
      if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
        bytes = gzip.decode(bytes);
      }

      // Try UTF-8 decode
      String body;
      try {
        body = utf8.decode(bytes);
      } catch (_) {
        body = utf8.decode(bytes, allowMalformed: true);
      }

      _appendLog('✅ 状态码: ${response.statusCode}');
      _appendLog('📊 大小: ${bytes.length} bytes');
      _appendLog('🧪 内容预览: ${body.substring(0, body.length > 200 ? 200 : body.length)}');
      
      setState(() => _rawResponse = body);
    } catch (e) {
      _appendLog('❌ 请求失败: $e');
    } finally {
      if (mounted) setState(() => _isDebugLoading = false);
    }
  }
}
