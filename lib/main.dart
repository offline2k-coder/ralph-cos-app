import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.scheduleMorningPush();
    await notificationService.scheduleEveningRitualReminder();
    await notificationService.scheduleSundayStrategicReminder();
  } catch (e) {
    debugPrint('Notification setup failed: $e');
  }

  // Initialize background sync
  try {
    await BackgroundSyncService().initialize();
    await BackgroundSyncService().scheduleNightSync();
  } catch (e) {
    debugPrint('Background sync setup failed: $e');
  }

  runApp(const RalphCoSApp());
}

class RalphCoSApp extends StatelessWidget {
  const RalphCoSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ralph-CoS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
