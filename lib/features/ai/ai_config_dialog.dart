import 'package:flutter/material.dart';

import '../../services/ai_config_prefs.dart';
import '../../services/ai_config_http_service.dart';

/// AI 配置 — 对齐 Jingshiro `dialog_ai_config.xml` / `AiConfigDialog`
class AiConfigDialog extends StatefulWidget {
  const AiConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AiConfigDialog(),
    );
  }

  @override
  State<AiConfigDialog> createState() => _AiConfigDialogState();
}

class _AiConfigDialogState extends State<AiConfigDialog> {
  final _httpService = AiConfigHttpService();
  late final TextEditingController _apiUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late final TextEditingController _userAvatar;
  late final TextEditingController _aiAvatar;
  late final TextEditingController _persona;
  bool _toolEnabled = true;
  bool _loading = true;
  bool _busy = false;
  String? _message;
  AiConfigPrefs? _prefs;

  @override
  void initState() {
    super.initState();
    _apiUrl = TextEditingController();
    _apiKey = TextEditingController();
    _model = TextEditingController();
    _userAvatar = TextEditingController();
    _aiAvatar = TextEditingController();
    _persona = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _apiUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _userAvatar.dispose();
    _aiAvatar.dispose();
    _persona.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await AiConfigPrefs.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _apiUrl.text = prefs.apiUrl;
      _apiKey.text = prefs.apiKey;
      _model.text = prefs.model;
      _userAvatar.text = prefs.userAvatar;
      _aiAvatar.text = prefs.aiAvatar;
      _persona.text = prefs.persona;
      _toolEnabled = prefs.toolEnabled;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = _prefs ?? AiConfigPrefs();
    prefs
      ..apiUrl = _apiUrl.text.trim()
      ..apiKey = _apiKey.text.trim()
      ..model = _model.text.trim()
      ..userAvatar = _userAvatar.text.trim()
      ..aiAvatar = _aiAvatar.text.trim()
      ..persona = _persona.text.trim()
      ..toolEnabled = _toolEnabled;
    await prefs.save();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _message = '配置已保存';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI 配置已保存')));
    }
  }

  Future<void> _fetchModels() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final base = _apiUrl.text.trim();
      final ids = await _httpService.fetchModels(
        apiUrl: base,
        apiKey: _apiKey.text,
      );
      if (!mounted) return;
      if (ids.isEmpty) {
        setState(() => _message = '未解析到模型列表');
        return;
      }
      final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('选择模型'),
          children: [
            SizedBox(
              width: double.maxFinite,
              height: 360,
              child: ListView.builder(
                itemCount: ids.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(ids[i], style: const TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(ctx, ids[i]),
                ),
              ),
            ),
          ],
        ),
      );
      if (chosen != null && mounted) {
        setState(() => _model.text = chosen);
      }
    } catch (e) {
      if (mounted) setState(() => _message = '获取模型失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testModel() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final code = await _httpService.testModel(
        apiUrl: _apiUrl.text,
        model: _model.text,
        apiKey: _apiKey.text,
      );
      if (!mounted) return;
      if (code >= 200 && code < 300) {
        setState(() => _message = '模型可用（HTTP $code）');
      } else {
        setState(() => _message = '测试失败 HTTP $code');
      }
    } catch (e) {
      if (mounted) setState(() => _message = '测试失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMemory() async {
    await AiMemoryDialog.show(context);
    final prefs = await AiConfigPrefs.load();
    if (mounted) setState(() => _prefs = prefs);
  }

  Future<void> _clearMemory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除记忆'),
        content: const Text('确定清除全部 AI 对话记忆？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = _prefs ?? await AiConfigPrefs.load();
    await prefs.clearMemory();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _message = '记忆已清除';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (ctx, scrollCtrl) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                AppBar(
                  title: const Text('AI 助手'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            TextField(
                              controller: _apiUrl,
                              decoration: const InputDecoration(
                                labelText: 'API URL',
                                hintText:
                                    'https://api.openai.com/v1/chat/completions',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _apiKey,
                              decoration: const InputDecoration(
                                labelText: 'API Key',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'API Key 仅保存在本机，请勿泄露',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _model,
                              decoration: const InputDecoration(
                                labelText: '模型',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busy ? null : _fetchModels,
                                    child: const Text('获取模型列表'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busy ? null : _testModel,
                                    child: const Text('测试模型可用性'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _userAvatar,
                              decoration: const InputDecoration(
                                labelText: '用户头像 URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _aiAvatar,
                              decoration: const InputDecoration(
                                labelText: 'AI 头像 URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _persona,
                              minLines: 3,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText: '人设 / System Prompt',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('启用工具调用'),
                              value: _toolEnabled,
                              onChanged: (v) =>
                                  setState(() => _toolEnabled = v),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('记忆条数'),
                              trailing: Text(
                                '${_prefs?.memoryList.length ?? 0}',
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _openMemory,
                                    child: const Text('查看记忆列表'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _clearMemory,
                                    child: Text(
                                      '清除记忆',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 12),
                              Text(_message!),
                            ],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _busy ? null : _save,
                              child: const Text('保存配置'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// AI 记忆列表 — 对齐 `dialog_ai_memory.xml`
class AiMemoryDialog extends StatefulWidget {
  const AiMemoryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AiMemoryDialog(),
    );
  }

  @override
  State<AiMemoryDialog> createState() => _AiMemoryDialogState();
}

class _AiMemoryDialogState extends State<AiMemoryDialog> {
  List<AiMemoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await AiConfigPrefs.load();
    if (!mounted) return;
    setState(() {
      _items = prefs.memoryList;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    final prefs = await AiConfigPrefs.load();
    await prefs.clearMemory();
    if (mounted) {
      setState(() => _items = []);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('记忆已清除')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              AppBar(
                title: const Text('AI 对话记忆'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                    ? const Center(child: Text('暂无记忆'))
                    : ListView.separated(
                        controller: scrollCtrl,
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final m = _items[i];
                          return ListTile(
                            title: Text(
                              m.chapterRange.isEmpty
                                  ? '会话 ${m.id}'
                                  : m.chapterRange,
                            ),
                            subtitle: Text(m.preview),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: TextButton(
                  onPressed: _items.isEmpty ? null : _clearAll,
                  child: Text(
                    '清除全部记忆',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
