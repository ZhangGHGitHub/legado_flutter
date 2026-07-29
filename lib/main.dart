import 'package:flutter/widgets.dart';

import 'bootstrap/app_composition_root.dart';

export 'application/app_bootstrap.dart' show loadStartupBookProgress;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 整站关闭语义曾与阅读器正文空白并存，阅读器只允许局部管理语义树。
  await AppCompositionRoot.run();
}
