import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/donate_clipboard_port.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/legado_card.dart';

/// 捐赠页 — 对齐 Jingshiro/legado [activity_donate.xml] + 经典 [DonateFragment]/donate.xml]
///
/// 现仓布局仅为 TitleBar + Fragment 容器；具体渠道项来自历史上移除前的 Preference 列表。
class DonatePage extends StatelessWidget {
  const DonatePage({super.key, this.clipboard});

  final DonateClipboardPort? clipboard;

  /// 原作者公开收款码图片（gedoor.github.io）
  static const wxAppreciationQrUrl =
      'https://gedoor.github.io/assets/images/wxskrwm-d8e6963d6ae122a3c2e818f3c4bc09cf.jpg';
  static const alipayRedEnvelopeQrUrl =
      'https://gedoor.github.io/assets/images/zfbhbrwm-6dfbcd1d680cfd831b93490a91052656.png';
  static const alipayPaymentQrUrl =
      'https://gedoor.github.io/assets/images/zfbskrwm-66379bdee8214093872696e413f6dda9.jpg';
  static const qqCollectionQrUrl =
      'https://gedoor.github.io/assets/images/qqskrwm-2c10b25f67f4354eec5ab5bd6080285f.jpg';

  static const wechatOfficialAccount = '开源阅读';
  static const alipayRedEnvelopeCode = '537954522';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('捐赠'),
            Text(
              '您的支持是我更新的动力',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LegadoTokens.spacingMd),
        children: [
          _DonateSection(
            title: '微信',
            children: [
              _DonateTile(
                title: '关注公众号',
                subtitle: '公众号【开源阅读】',
                onTap: () => _copy(
                  context,
                  wechatOfficialAccount,
                  '已复制：$wechatOfficialAccount',
                ),
              ),
              const Divider(height: 1),
              _DonateTile(
                title: '微信赞赏码',
                subtitle: '点击打开',
                onTap: () => _openUrl(context, wxAppreciationQrUrl),
              ),
            ],
          ),
          const SizedBox(height: LegadoTokens.spacingMd),
          _DonateSection(
            title: '支付宝',
            children: [
              _DonateTile(
                title: '支付宝红包搜索码',
                subtitle: '537954522 点击复制',
                onTap: () => _copyAlipayCode(context),
              ),
              const Divider(height: 1),
              _DonateTile(
                title: '支付宝红包二维码',
                subtitle: '点击打开',
                onTap: () => _openUrl(context, alipayRedEnvelopeQrUrl),
              ),
              const Divider(height: 1),
              _DonateTile(
                title: '支付宝收款二维码',
                subtitle: '点击打开',
                onTap: () => _openUrl(context, alipayPaymentQrUrl),
              ),
            ],
          ),
          const SizedBox(height: LegadoTokens.spacingMd),
          _DonateSection(
            title: 'QQ',
            children: [
              _DonateTile(
                title: 'QQ 收款二维码',
                subtitle: '点击打开',
                onTap: () => _openUrl(context, qqCollectionQrUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开链接：$url')));
    }
  }

  Future<void> _copy(BuildContext context, String text, String toast) async {
    await (clipboard ?? const PlatformDonateClipboard()).copyText(text);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(toast)));
    }
  }

  Future<void> _copyAlipayCode(BuildContext context) async {
    await (clipboard ?? const PlatformDonateClipboard()).copyText(
      alipayRedEnvelopeCode,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('高级功能已解锁\n请等待邮箱确认\n支付宝首页搜索「537954522」领取红包')),
    );
    final alipay = Uri.parse('alipays://platformapi/startapp');
    try {
      if (await canLaunchUrl(alipay)) {
        await launchUrl(alipay, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // 未安装支付宝时忽略，已复制搜索码
    }
  }
}

class _DonateSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DonateSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: LegadoTokens.spacingSm,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        LegadoCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DonateTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DonateTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
