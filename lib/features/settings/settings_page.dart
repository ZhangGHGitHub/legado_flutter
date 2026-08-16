import 'package:flutter/material.dart';

import '../../features/my/my_page.dart';

/// 兼容旧路由 `/settings`
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const MyPage();
}
