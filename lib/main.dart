import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'providers/library_provider.dart';

/// 应用入口
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面端: 使用 sqflite_common_ffi 替代原生 sqflite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(
    // 注入全局状态
    ChangeNotifierProvider(
      create: (_) => LibraryProvider()..initialize(),
      child: const LegadoApp(),
    ),
  );
}
