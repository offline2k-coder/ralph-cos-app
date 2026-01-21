import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'git_sync_service.dart';
import 'database_service.dart';

class KpiTrackingService {
  static final KpiTrackingService _instance = KpiTrackingService._internal();
  factory KpiTrackingService() => _instance;
  KpiTrackingService._internal();

  final _gitSync = GitSyncService();
  final _db = DatabaseService();

  Future<String> get _kpiFilePath async {
    final repoPath = await _gitSync.repoPath;
    final logsDir = Directory('$repoPath/ralph_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    return '$repoPath/ralph_logs/daily_kpis.json';
  }

  Future<List<dynamic>> _loadExistingKpis() async {
    try {
      final filePath = await _kpiFilePath;
      final file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) return [];

      final data = jsonDecode(contents);
      return data is List ? data : [];
    } catch (e) {
      print('KpiTrackingService: Error loading KPIs - $e');
      return [];
    }
  }

  Future<void> _saveKpis(List<dynamic> kpis) async {
    try {
      final repoPath = await _gitSync.repoPath;
      final filePath = '$repoPath/ralph_logs/daily_kpis.json';
      final file = File(filePath);

      // Ensure directory exists
      await file.parent.create(recursive: true);

      final jsonString = const JsonEncoder.withIndent('  ').convert(kpis);
      await file.writeAsString(jsonString);

      print('KpiTrackingService: Saved KPIs to $filePath');

      // Trigger Git Sync
      await _gitSync.sync();
    } catch (e) {
      print('KpiTrackingService: Error saving KPIs - $e');
    }
  }

  Future<void> trackDailyCheckIn() async {
    try {
      final streak = await _db.getStreakData();
      if (streak == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _addToConsolidatedTracking({
        'type': 'check_in',
        'date': today,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'current_streak': streak.currentStreak,
          'passes_available': streak.passesAvailable,
          'total_days': streak.totalDays,
          'longest_streak': streak.longestStreak,
        },
      });
    } catch (e) {
      print('KpiTrackingService: Error tracking check-in - $e');
    }
  }

  Future<void> trackChallengeCompletion(int day, int streak) async {
    // Already tracked in syncChallengeCompletionToGitHub
    // No separate tracking needed
  }

  Future<void> trackEveningReflection({
    required bool keptVow,
    required bool inboxZero,
    required bool taskZero,
    required bool guiltZero,
  }) async {
    // Already tracked in syncEveningReflectionToGitHub
    // No separate tracking needed
  }

  Future<void> trackStreakBreak(int previousStreak) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      await _addToConsolidatedTracking({
        'type': 'streak_break',
        'date': today,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'previous_streak': previousStreak,
        },
      });
    } catch (e) {
      print('KpiTrackingService: Error tracking streak break - $e');
    }
  }

  Future<void> trackPassEarned(int newPassCount) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      await _addToConsolidatedTracking({
        'type': 'pass_earned',
        'date': today,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'total_passes': newPassCount,
        },
      });
    } catch (e) {
      print('KpiTrackingService: Error tracking pass earned - $e');
    }
  }

  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final kpis = await _loadExistingKpis();
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final weekKpis = kpis.where((k) {
        final date = DateTime.parse(k['date']);
        return date.isAfter(weekAgo) && date.isBefore(now.add(const Duration(days: 1)));
      }).toList();

      int checkIns = 0;
      int challengeCompletions = 0;
      int eveningReflections = 0;
      int vowsKept = 0;
      int zerosAchieved = 0;

      for (final kpi in weekKpis) {
        switch (kpi['event']) {
          case 'check_in':
            checkIns++;
            break;
          case 'challenge_completion':
            challengeCompletions++;
            break;
          case 'evening_reflection':
            eveningReflections++;
            if (kpi['data']['kept_vow'] == true) vowsKept++;
            zerosAchieved += (kpi['data']['zeros_achieved'] as int? ?? 0);
            break;
        }
      }

      return {
        'period': '7 days',
        'check_ins': checkIns,
        'challenge_completions': challengeCompletions,
        'evening_reflections': eveningReflections,
        'vows_kept': vowsKept,
        'total_zeros_achieved': zerosAchieved,
      };
    } catch (e) {
      print('KpiTrackingService: Error getting weekly summary - $e');
      return {};
    }
  }

  Future<void> syncEveningReflectionToGitHub({
    required String date,
    required String mantra,
    required bool keptVow,
    required String whatAvoided,
    required bool inboxZero,
    required bool taskZero,
    required bool guiltZero,
    String? reflection,
  }) async {
    // Add to consolidated tracking
    await _addToConsolidatedTracking({
      'type': 'evening_reflection',
      'date': date,
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'mantra': mantra,
        'kept_vow': keptVow,
        'what_avoided': whatAvoided,
        'inbox_zero': inboxZero,
        'task_zero': taskZero,
        'guilt_zero': guiltZero,
        'zeros_achieved': [inboxZero, taskZero, guiltZero].where((z) => z).length,
        'reflection': reflection,
      },
    });
  }

  Future<void> syncChallengeCompletionToGitHub({
    required int day,
    required String date,
    required String dailyTask,
    required String reflection,
    required String emotion,
    required String oneSentence,
    String? aiSummary,
  }) async {
    // Add to consolidated tracking
    await _addToConsolidatedTracking({
      'type': 'challenge_completion',
      'date': date,
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'day': day,
        'task': dailyTask,
        'reflection': reflection,
        'emotion': emotion,
        'one_sentence': oneSentence,
        'ai_summary': aiSummary,
      },
    });
  }

  Future<void> syncDailyEmotionToGitHub({
    required String date,
    required String emotion,
    required String source,
    String? context,
  }) async {
    // Emotions are now included in challenge_completion or evening_reflection
    // No separate tracking needed
  }

  Future<void> _addToConsolidatedTracking(Map<String, dynamic> entry) async {
    try {
      final repoPath = await _gitSync.repoPath;
      final filePath = '$repoPath/ralph_logs/ralph_tracking.json';
      final file = File(filePath);

      List<dynamic> allData = [];

      // 1. Read local file directly (instead of HTTP GET from API)
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            allData = json.decode(content);
          }
        } catch (e) {
          print('KpiTrackingService: Error reading tracking file, starting fresh');
        }
      } else {
        await file.parent.create(recursive: true);
      }

      // 2. Add new entry
      allData.add(entry);

      // 3. Sort by date, then timestamp
      allData.sort((a, b) {
        final dateCompare = (a['date'] as String).compareTo(b['date'] as String);
        if (dateCompare != 0) return dateCompare;
        return (a['timestamp'] as String).compareTo(b['timestamp'] as String);
      });

      // 4. Save locally
      final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
      await file.writeAsString(jsonString);

      // 5. Trigger Git Sync (Write-back)
      final success = await _gitSync.sync();
      if (success) {
        print('KpiTrackingService: Consolidated tracking synced to GitHub via Git');
      }
    } catch (e) {
      print('KpiTrackingService: Error updating consolidated tracking - $e');
    }
  }
}
