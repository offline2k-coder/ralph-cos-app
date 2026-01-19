import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'git_sync_service.dart';
import 'content_parser_service.dart';
import 'database_service.dart';
import '../core/app_constants.dart';

// Background callback function must be top-level
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((task, inputData) async {
    print('BackgroundSync: Starting sync task at ${DateTime.now()}');

    try {
      final gitSync = GitSyncService();
      final parser = ContentParserService();
      final db = DatabaseService();

      // Clone or pull repo
      final success = await gitSync.cloneOrPullRepo();

      if (success) {
        print('BackgroundSync: Repo sync successful');

        // Parse content
        final tasks = await parser.parseAllContent();
        print('BackgroundSync: Parsed ${tasks.length} tasks');

        // Update database
        await db.clearAllTasks();
        await db.insertTasks(tasks);
        print('BackgroundSync: Database updated');

        return Future.value(true);
      } else {
        print('BackgroundSync: Repo sync failed');
        return Future.value(false);
      }
    } catch (e) {
      print('BackgroundSync: Error during sync - $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  static const String _nightSyncTask = 'night-sync-task';

  Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        backgroundSyncCallback,
        isInDebugMode: false,
      );

      print('BackgroundSyncService: Workmanager initialized');
    } catch (e) {
      print('BackgroundSyncService: Error initializing - $e');
    }
  }

  Future<void> scheduleNightSync() async {
    try {
      // Cancel any existing tasks
      await Workmanager().cancelAll();

      // Calculate next sync time from CET
      final now = DateTime.now().toUtc();
      
      // CET is typically UTC+1, so 03:00 CET is 02:00 UTC
      // Adjust if Daylight Savings is a concern, but following original logic for now
      final utcSyncHour = AppConstants.nightSyncHour - 1; 

      DateTime nextSync = DateTime.utc(
        now.year,
        now.month,
        now.day,
        utcSyncHour,
        0,
      );

      // If it's already past the sync hour today, schedule for tomorrow
      if (now.hour >= utcSyncHour) {
        nextSync = nextSync.add(const Duration(days: 1));
      }

      final delay = nextSync.difference(now);
      final initialDelayMinutes = delay.inMinutes;

      print('BackgroundSyncService: Scheduling sync in $initialDelayMinutes minutes (${delay.inHours}h ${delay.inMinutes % 60}m)');

      // Schedule periodic task that runs daily at 03:00 CET
      await Workmanager().registerPeriodicTask(
        _nightSyncTask,
        _nightSyncTask,
        frequency: const Duration(hours: 24),
        initialDelay: Duration(minutes: initialDelayMinutes),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      print('BackgroundSyncService: Night sync scheduled successfully');
    } catch (e) {
      print('BackgroundSyncService: Error scheduling sync - $e');
    }
  }

  Future<void> cancelNightSync() async {
    try {
      await Workmanager().cancelByUniqueName(_nightSyncTask);
      print('BackgroundSyncService: Night sync cancelled');
    } catch (e) {
      print('BackgroundSyncService: Error cancelling sync - $e');
    }
  }

  Future<void> runSyncNow() async {
    try {
      await Workmanager().registerOneOffTask(
        'manual-sync-task',
        'manual-sync-task',
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      print('BackgroundSyncService: Manual sync triggered');
    } catch (e) {
      print('BackgroundSyncService: Error running manual sync - $e');
    }
  }
}
