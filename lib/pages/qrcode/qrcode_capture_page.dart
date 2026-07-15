import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/qr_code_service.dart';

/// 扫码页 — 1:1 对齐 Jingshiro [activity_qrcode_capture.xml] + [QrCodeActivity]。
///
/// - TitleBar：`scan_qr_code` →「扫描二维码」
/// - 菜单：`gallery` →「图库」（选图解码）
/// - 有相机时：全屏预览扫描（对齐 QrCodeFragment）
/// - Windows/Linux 等无相机平台：图库 + 粘贴内容回退（不伪造 Android 主 UI）
class QrCodeCapturePage extends StatefulWidget {
  const QrCodeCapturePage({super.key});

  /// mobile_scanner 官方平台表：Android / iOS / macOS / Web 支持；Windows / Linux 否。
  static bool get supportsLiveCamera {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  @override
  State<QrCodeCapturePage> createState() => _QrCodeCapturePageState();
}

class _QrCodeCapturePageState extends State<QrCodeCapturePage> {
  MobileScannerController? _controller;
  bool _handling = false;
  bool _cameraFailed = false;

  bool get _useCamera =>
      QrCodeCapturePage.supportsLiveCamera && !_cameraFailed;

  @override
  void initState() {
    super.initState();
    if (QrCodeCapturePage.supportsLiveCamera) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _finishWithResult(String? text) async {
    if (_handling) return;
    final value = text?.trim();
    if (value == null || value.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未识别到二维码')),
        );
      }
      return;
    }
    _handling = true;
    await _controller?.stop();
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  Future<void> _pickFromGallery() async {
    if (_handling) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      var bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法读取图片')),
          );
        }
        return;
      }
      final text = await compute(QrCodeService.decodeFromImageBytes, bytes);
      await _finishWithResult(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图库识别失败: $e')),
        );
      }
    }
  }

  Future<void> _pasteContent() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('粘贴内容'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '粘贴书源 JSON 或订阅 URL…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    await _finishWithResult(text);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handling) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _finishWithResult(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        actions: [
          TextButton(
            onPressed: _pickFromGallery,
            child: Text(
              '图库',
              style: TextStyle(color: scheme.onSurface),
            ),
          ),
        ],
      ),
      body: _useCamera ? _buildCameraBody(scheme) : _buildFallbackBody(scheme),
    );
  }

  Widget _buildCameraBody(ColorScheme scheme) {
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      errorBuilder: (context, error) {
        // 权限拒绝 / 无相机 → 回退，不伪造预览
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_cameraFailed) {
            setState(() => _cameraFailed = true);
          }
        });
        return ColoredBox(
          color: scheme.surface,
          child: Center(
            child: Text(
              '相机不可用',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackBody(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '当前设备无可用相机，请从图库选择含二维码的图片，或粘贴书源内容。',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('图库'),
          subtitle: const Text('扫描本地图片'),
          onTap: _pickFromGallery,
        ),
        ListTile(
          leading: const Icon(Icons.content_paste_outlined),
          title: const Text('粘贴内容'),
          subtitle: const Text('书源 JSON 或订阅 URL'),
          onTap: _pasteContent,
        ),
      ],
    );
  }
}
