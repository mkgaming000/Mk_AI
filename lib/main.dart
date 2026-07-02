import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/di/injection_container.dart';
import 'core/services/notification_service.dart';
import 'core/storage/database/hive_boxes.dart';
import 'core/storage/local_storage_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF07070F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);
  HiveBoxes.registerAdapters();
  await HiveBoxes.openAllBoxes();

  await initDependencies();
  await LocalStorageService.instance.initDefaults();
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: OmniForgeApp(),
    ),
  );
}
