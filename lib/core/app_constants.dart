class AppConstants {
  // Check-in window
  static const int checkInStartHour = 5;
  static const int checkInEndHour = 9;

  // Ritual windows
  static const int morningVowEndHour = 10;
  static const int eveningRitualStartHour = 17;
  
  // Sunday Strategic Reset
  static const int sundayStrategicStartHour = 13;
  static const int sundayStrategicEndHour = 22;

  // Streak/Rewards
  static const int daysPerPass = 20;
  static const int maxPasses = 3;

  // Background Sync
  static const int nightSyncHour = 3; // 03:00 CET

  // GitHub Repo
  static const String githubRepoName = 'my-notion-backup';
  static const String githubOwner = 'offline2k-coder';

  // Discipline Cutoffs
  static const int streakBreakHour = 9;
  static const int streakBreakMinute = 1;
}
