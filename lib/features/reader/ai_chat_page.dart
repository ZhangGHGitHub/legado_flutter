import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/ai/ai_config_prefs_port.dart';
import '../../widgets/empty_state.dart';
import '../ai/ai_config_dialog.dart';

/// AI 助手占位 — 对齐 AiChatActivity（配置已落地，对话待接）
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, this.isStandalone = true, this.prefsPort});

  /// true=从我的页进入；false=从阅读器进入
  final bool isStandalone;
  final AiConfigPrefsPort? prefsPort;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  AiConfigSettings? _prefs;

  AiConfigPrefsPort get _prefsPort =>
      widget.prefsPort ?? context.read<AiConfigPrefsPort>();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final p = await _prefsPort.load();
    if (mounted) setState(() => _prefs = p);
  }

  Future<void> _openConfig() async {
    await AiConfigDialog.show(context, prefsPort: _prefsPort);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final configured =
        (_prefs?.apiKey.isNotEmpty ?? false) ||
        (_prefs?.apiUrl.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        leading: widget.isStandalone ? null : const BackButton(),
        actions: [
          IconButton(
            tooltip: 'AI 配置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openConfig,
          ),
          IconButton(
            tooltip: '对话记忆',
            icon: const Icon(Icons.history),
            onPressed: () async {
              await AiMemoryDialog.show(context, prefsPort: _prefsPort);
              await _reload();
            },
          ),
        ],
      ),
      body: EmptyState(
        icon: Icons.smart_toy_outlined,
        title: configured ? '配置已就绪' : '请先配置 AI',
        subtitle: configured
            ? '模型：${_prefs?.model ?? "-"}\n'
                  '对话界面开发中；可点右上角修改配置 / 查看记忆'
            : (widget.isStandalone
                  ? '独立模式：从我的页进入\n点右上角齿轮配置 API URL / Key / 模型'
                  : '阅读模式：从阅读器进入\n点右上角齿轮配置后再使用'),
        actionLabel: configured ? '打开配置' : '去配置',
        onAction: _openConfig,
      ),
    );
  }
}
