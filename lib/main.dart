import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'app.dart';
import 'providers/book_provider.dart';
import 'providers/source_provider.dart';
import 'providers/replace_provider.dart';

/// 应用入口
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面端 (Windows/Linux/macOS): 使用 sqflite_common_ffi 替代原生 sqflite
  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // 注入全局状态
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => ReplaceProvider()..loadRules()),
      ],
      child: const LegadoApp(),
    ),
  );
}
