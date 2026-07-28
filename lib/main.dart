import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'application/app_bootstrap.dart';
import 'config/app_config.dart';
import 'database/dao/replace_rule_dao.dart';
import 'database/dao/source_dao.dart';
import 'domain/ports/backup_local_file_port.dart';
import 'domain/ports/book_source_debug_port.dart';
import 'domain/ports/book_source_validation_port.dart';
import 'domain/ports/legacy_room_import_use_case.dart';
import 'domain/ports/rss_source_import_port.dart';
import 'domain/ports/webdav_repository.dart';
import 'infrastructure/file_system/backup_local_file_adapter.dart';
import 'infrastructure/engine/frb_book_source_debug_port.dart';
import 'infrastructure/engine/frb_book_source_validation_port.dart';
import 'infrastructure/webdav/frb_webdav_repository.dart';
import 'infrastructure/network/io_rss_source_import_port.dart';
import 'providers/source_provider.dart';
import 'providers/replace_provider.dart';
import 'providers/rss_provider.dart';
import 'services/backup_service.dart';

export 'application/app_bootstrap.dart' show loadStartupBookProgress;

/// 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注意：不要在此调用 setSemanticsTreeEnabled(false) / 整站 ExcludeSemantics。
  // 整站关闭语义曾与阅读器正文空白并存；AXTree 压制改到阅读器页内（见 reader_page）。

  final bootstrap = await const AppBootstrap().initialize();
  final bookProvider = bootstrap.bookProvider;
  final themeController = bootstrap.themeController;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: AppConfig.instance),
        ChangeNotifierProvider.value(value: bookProvider),
        Provider<BookSourceDebugPort>(create: (_) => FrbBookSourceDebugPort()),
        Provider<BookSourceValidationPort>(
          create: (_) => FrbBookSourceValidationPort(),
        ),
        Provider<WebDavRepository>(create: (_) => const FrbWebDavRepository()),
        Provider<BackupService>(create: (_) => BackupService()),
        Provider<BackupLocalFilePort>(
          create: (context) =>
              FileSystemBackupLocalFileAdapter(context.read<BackupService>()),
        ),
        Provider<LegacyRoomImportUseCase>.value(
          value: bootstrap.legacyRoomImportService,
        ),
        Provider<RssSourceImportPort>(
          create: (_) => const IoRssSourceImportPort(),
        ),
        ChangeNotifierProvider(
          create: (context) => SourceProvider(
            repository: SourceDao(),
            validationPort: context.read<BookSourceValidationPort>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ReplaceProvider(repository: ReplaceRuleDao())..loadRules(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              RssProvider(sourceImportPort: context.read<RssSourceImportPort>())
                ..loadSources(),
        ),
      ],
      child: const LegadoApp(),
    ),
  );
}
