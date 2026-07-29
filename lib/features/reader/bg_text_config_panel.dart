import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/ports/application_binary_http_request_port.dart';
import '../../models/read_style_config.dart';
import '../../services/read_style_zip_service.dart';
import 'reader_settings.dart';

/// 文字颜色和背景配置（对齐 `dialog_read_bg_text` + 长按主题入口）
class BgTextConfigPanel {
  BgTextConfigPanel._();

  /// 返回更新后的槽位覆盖；取消则 null。
  static Future<BgTextConfigResult?> show(
    BuildContext context, {
    required String themeName,
    required String themeLabel,
    required ReaderTheme baseTheme,
    ReadStyleSlotOverride? initialOverride,
    required ReaderSettings settings,
  }) {
    return showModalBottomSheet<BgTextConfigResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BgTextConfigSheet(
        themeName: themeName,
        themeLabel: themeLabel,
        baseTheme: baseTheme,
        initialOverride: initialOverride,
        settings: settings,
      ),
    );
  }
}

class BgTextConfigResult {
  final ReadStyleSlotOverride override;
  final ReaderSettings? appliedTypography;
  final bool cleared;

  const BgTextConfigResult({
    required this.override,
    this.appliedTypography,
    this.cleared = false,
  });
}

class _BgTextConfigSheet extends StatefulWidget {
  final String themeName;
  final String themeLabel;
  final ReaderTheme baseTheme;
  final ReadStyleSlotOverride? initialOverride;
  final ReaderSettings settings;

  const _BgTextConfigSheet({
    required this.themeName,
    required this.themeLabel,
    required this.baseTheme,
    required this.initialOverride,
    required this.settings,
  });

  @override
  State<_BgTextConfigSheet> createState() => _BgTextConfigSheetState();
}

class _BgTextConfigSheetState extends State<_BgTextConfigSheet> {
  late final ReadStyleZipService _zip;
  late String _name;
  late Color _bg;
  late Color _text;
  late Color _accent;
  late bool _darkStatusIcon;
  String? _bgImagePath;
  bool _busy = false;
  ReaderSettings? _typographyFromZip;

  @override
  void initState() {
    super.initState();
    _zip = ReadStyleZipService(
      context.read<ApplicationBinaryHttpRequestPort>(),
    );
    final o = widget.initialOverride;
    _name = o?.name?.isNotEmpty == true ? o!.name! : widget.themeLabel;
    _bg = o?.background ?? widget.baseTheme.background;
    _text = o?.text ?? widget.baseTheme.text;
    _accent = o?.accent ?? widget.baseTheme.progress;
    _darkStatusIcon = o?.darkStatusIcon ?? true;
    _bgImagePath = o?.bgImagePath;
  }

  ReadStyleSlotOverride get _currentOverride => ReadStyleSlotOverride(
    name: _name,
    background: _bg,
    text: _text,
    accent: _accent,
    bgImagePath: _bgImagePath,
    darkStatusIcon: _darkStatusIcon,
  );

  Future<void> _pickColor({
    required String title,
    required Color current,
    required ValueChanged<Color> onPicked,
  }) async {
    final swatches = <Color>[
      current,
      Colors.white,
      const Color(0xFFF5F0E8),
      const Color(0xFFC7EDCC),
      const Color(0xFF1E1E1E),
      const Color(0xFF3C3C3C),
      const Color(0xFF333333),
      const Color(0xFFCCCCCC),
      Colors.black,
      Colors.orange,
      Colors.blue,
      Colors.tealAccent,
      Colors.green,
      const Color(0xFFF44336),
    ];
    final hexCtrl = TextEditingController(
      text: ReadStyleColorMapper.toHex(current).substring(1),
    );
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: hexCtrl,
                decoration: const InputDecoration(
                  labelText: '颜色值 (#RRGGBB)',
                  prefixText: '#',
                  isDense: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: swatches.map((c) {
                  final selected = c.toARGB32() == current.toARGB32();
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? Theme.of(ctx).colorScheme.primary
                              : Colors.grey,
                          width: selected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                '长按输入颜色值',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final c = ReadStyleColorMapper.parse('#${hexCtrl.text}');
              if (c != null) Navigator.pop(ctx, c);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    hexCtrl.dispose();
    if (picked != null) onPicked(picked);
  }

  Future<void> _importZip() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('本地导入'),
              onTap: () => Navigator.pop(ctx, 'local'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('网络导入'),
              onTap: () => Navigator.pop(ctx, 'net'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'net') {
      await _importNet();
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() => _busy = true);
    try {
      final bytes =
          file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) throw const FormatException('无法读取 zip');
      final config = await _zip.importBytes(Uint8List.fromList(bytes));
      _applyImported(config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导入成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importNet() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入地址'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://…/xxx.zip',
            isDense: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (url == null || url.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final config = await _zip.importFromUrl(url);
      _applyImported(config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导入成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyImported(ReadStyleConfig config) {
    final isNight = widget.themeName == 'dark';
    final bg = isNight
        ? (config.nightBgColor ?? config.dayBgColor)
        : config.dayBgColor;
    final text = isNight
        ? (config.nightTextColor ?? config.dayTextColor)
        : config.dayTextColor;
    final accent = isNight
        ? (config.nightAccentColor ?? config.dayAccentColor)
        : config.dayAccentColor;
    setState(() {
      if (config.name.isNotEmpty) _name = config.name;
      if (bg != null) _bg = bg;
      if (text != null) _text = text;
      if (accent != null) _accent = accent;
      _darkStatusIcon = config.darkStatusIcon;
      final img = isNight && config.bgTypeNight == 2
          ? config.bgStrNight
          : (config.bgType == 2 ? config.bgStr : null);
      if (img != null && img.isNotEmpty) _bgImagePath = img;
      // 排版字段映射到 ReaderSettings（字体文件路径需 FontLoader，暂不写入 fontFamily）
      _typographyFromZip = widget.settings.copyWith(
        fontSize: config.textSize.toDouble().clamp(12, 40),
        letterSpacing: config.letterSpacing,
        lineHeight: (1.0 + config.lineSpacingExtra / 20).clamp(1.0, 3.0),
        paragraphSpacing: (config.paragraphSpacing / 10).clamp(0.0, 2.0),
        paddingHorizontal: ((config.paddingLeft + config.paddingRight) / 2)
            .toDouble(),
        paddingVertical: ((config.paddingTop + config.paddingBottom) / 2)
            .toDouble(),
        fontWeight: ReaderFontWeight.fromCode(config.textBold),
      );
    });
  }

  Future<void> _exportZip() async {
    setState(() => _busy = true);
    try {
      final isNight = widget.themeName == 'dark';
      final config = ReadStyleConfig(
        name: _name,
        bgStr: _bgImagePath != null && !isNight
            ? _bgImagePath!
            : ReadStyleColorMapper.toHex(_bg),
        bgStrNight: _bgImagePath != null && isNight
            ? _bgImagePath!
            : ReadStyleColorMapper.toHex(_bg),
        bgType: _bgImagePath != null && !isNight ? 2 : 0,
        bgTypeNight: _bgImagePath != null && isNight ? 2 : 0,
        textColor: ReadStyleColorMapper.toHex(_text),
        textColorNight: ReadStyleColorMapper.toHex(_text),
        textAccentColor: ReadStyleColorMapper.toHex(_accent),
        textAccentColorNight: ReadStyleColorMapper.toHex(_accent),
        textFont: widget.settings.fontFamily,
        textBold: widget.settings.fontWeight.code,
        textSize: widget.settings.fontSize.round(),
        letterSpacing: widget.settings.letterSpacing,
        lineSpacingExtra: ((widget.settings.lineHeight - 1.0) * 20).round(),
        paragraphSpacing: (widget.settings.paragraphSpacing * 10).round(),
        paddingLeft: widget.settings.paddingHorizontal.round(),
        paddingRight: widget.settings.paddingHorizontal.round(),
        paddingTop: widget.settings.paddingVertical.round(),
        paddingBottom: widget.settings.paddingVertical.round(),
        darkStatusIcon: _darkStatusIcon,
      );
      final bytes = await _zip.exportBytes(config);
      final safe = (_name.isEmpty ? 'readConfig' : _name).replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final fileName = '$safe.zip';
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: '导出',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saved == null ? '已取消导出' : '导出成功, 文件名为 $fileName'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _restorePreset() {
    setState(() {
      _name = widget.themeLabel;
      _bg = widget.baseTheme.background;
      _text = widget.baseTheme.text;
      _accent = widget.baseTheme.progress;
      _darkStatusIcon = true;
      _bgImagePath = null;
      _typographyFromZip = null;
    });
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('样式名称'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'name', isDense: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (next != null && mounted) setState(() => _name = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  '样式名称：',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    _name.isEmpty ? '文字' : _name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  tooltip: '编辑名称',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: _busy ? null : _editName,
                ),
                TextButton(
                  onPressed: _busy ? null : _restorePreset,
                  child: const Text('恢复默认'),
                ),
                IconButton(
                  tooltip: '导入',
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: _busy ? null : _importZip,
                ),
                IconButton(
                  tooltip: '导出',
                  icon: const Icon(Icons.file_upload_outlined),
                  onPressed: _busy ? null : _exportZip,
                ),
                IconButton(
                  tooltip: '删除自定义',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            BgTextConfigResult(
                              override: const ReadStyleSlotOverride(),
                              cleared: true,
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('深色状态栏图标', style: TextStyle(fontSize: 13)),
            value: _darkStatusIcon,
            onChanged: _busy
                ? null
                : (v) => setState(() => _darkStatusIcon = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _ColorAction(
                    label: '文字颜色',
                    color: _text,
                    onTap: () => _pickColor(
                      title: '文字颜色',
                      current: _text,
                      onPicked: (c) => setState(() => _text = c),
                    ),
                  ),
                ),
                Expanded(
                  child: _ColorAction(
                    label: '背景颜色',
                    color: _bg,
                    onTap: () => _pickColor(
                      title: '背景颜色',
                      current: _bg,
                      onPicked: (c) => setState(() {
                        _bg = c;
                        _bgImagePath = null;
                      }),
                    ),
                  ),
                ),
                Expanded(
                  child: _ColorAction(
                    label: '强调色',
                    color: _accent,
                    onTap: () => _pickColor(
                      title: '强调色',
                      current: _accent,
                      onPicked: (c) => setState(() => _accent = c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_bgImagePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '背景图片: ${_bgImagePath!.split(RegExp(r'[\\/]')).last}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          // 预览条
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
                image: _bgImagePath != null && File(_bgImagePath!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(_bgImagePath!)),
                        fit: BoxFit.cover,
                        opacity: 0.85,
                      )
                    : null,
              ),
              child: Text(
                '这是一段测试文字\n　　只是让你看看效果的',
                style: TextStyle(color: _text, fontSize: 15, height: 1.6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              BgTextConfigResult(
                                override: _currentOverride,
                                appliedTypography: _typographyFromZip,
                              ),
                            );
                          },
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
