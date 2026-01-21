import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/streak_data.dart';
import '../core/app_constants.dart';

final streakProvider = StateNotifierProvider<StreakNotifier, AsyncValue<StreakData>>((ref) {
  return StreakNotifier(DatabaseService());
});

class StreakNotifier extends StateNotifier<AsyncValue<StreakData>> {
  final DatabaseService _db;

  StreakNotifier(this._db) : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _db.getStreakData();
      if (data != null) {
        state = AsyncValue.data(data);
        await checkCutoff();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkCutoff() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final now = DateTime.now();
    final lastCheckIn = currentState.lastCheckIn;
    
    // Hard cutoff at 09:01
    final cutoff = DateTime(now.year, now.month, now.day, 
      AppConstants.streakBreakHour, AppConstants.streakBreakMinute);

    // If it's past cutoff and no check-in today
    if (now.isAfter(cutoff)) {
      final isSameDay = lastCheckIn.year == now.year && 
                       lastCheckIn.month == now.month && 
                       lastCheckIn.day == now.day;

      if (!isSameDay) {
        // Did we miss yesterday?
        final daysSinceLast = now.difference(lastCheckIn).inDays;
        if (daysSinceLast >= 1) {
          await _handleMissedDay(currentState);
        }
      }
    }
  }

  Future<void> _handleMissedDay(StreakData current) async {
    if (current.passesAvailable > 0) {
      // Auto-consume Mercy Pass
      final newData = current.copyWith(
        passesAvailable: current.passesAvailable - 1,
        lastCheckIn: DateTime.now(), // Use pass to count for today
      );
      await _db.updateStreakData(newData);
      state = AsyncValue.data(newData);
    } else {
      // RIP Streak
      final newData = current.copyWith(
        currentStreak: 0,
        lastCheckIn: DateTime.now(),
      );
      await _db.updateStreakData(newData);
      state = AsyncValue.data(newData);
    }
  }

  Future<void> completeDay(bool success) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    // Save Day Log
    await _db.saveDayLog(
      date: today,
      status: success ? 'WON' : 'LOST',
      locked: true,
    );

    if (success) {
      // Update Streak
      int newStreak = currentState.currentStreak + 1;
      int newPasses = currentState.passesAvailable;

      if (newStreak % AppConstants.daysPerPass == 0 && newPasses < AppConstants.maxPasses) {
        newPasses++;
      }

      final newData = currentState.copyWith(
        currentStreak: newStreak,
        passesAvailable: newPasses,
        lastCheckIn: now,
        totalDays: currentState.totalDays + 1,
        longestStreak: newStreak > currentState.longestStreak ? newStreak : currentState.longestStreak,
      );
      await _db.updateStreakData(newData);
      state = AsyncValue.data(newData);
    } else {
      // Day Lost
      await _handleMissedDay(currentState);
    }
  }
}
