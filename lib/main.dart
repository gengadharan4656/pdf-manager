import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'models/pdf_document.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for scanner accuracy
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hive init
  await Hive.initFlutter();
  Hive.registerAdapter(PdfFileAdapter());
  Hive.registerAdapter(PdfTagAdapter());
  await Hive.openBox<PdfFile>('documents');
  await Hive.openBox('settings');

  // Notifications
  await NotificationService.init(flutterLocalNotificationsPlugin);

  runApp(const ProviderScope(child: PdfManagerApp()));
}

class PdfManagerApp extends ConsumerWidget {
  const PdfManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PDF Manager Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
