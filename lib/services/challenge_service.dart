import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';
import 'kpi_tracking_service.dart';
import 'ai_inference_service.dart';
import 'notification_service.dart';
import '../data/default_challenge_template.dart';

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  final _database = DatabaseService();
  final _storage = SecureStorageService();
  final _kpiTracking = KpiTrackingService();
  final _aiService = AIInferenceService();
  final _notifications = NotificationService();

  Future<String?> extractDailyTask(String template, int day) async {
    try {
      // Parse the template to extract day X task directly
      final lines = template.split('\n');
      final dayPrefix = 'Day $day:';

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith(dayPrefix)) {
          // Found the day, get the rest of the paragraph
          String task = lines[i].trim().substring(dayPrefix.length).trim();

          // Continue reading lines until we hit an empty line or next day
          for (int j = i + 1; j < lines.length; j++) {
            final line = lines[j].trim();
            if (line.isEmpty || line.startsWith('Day ')) {
              break;
            }
            task += ' ' + line;
          }

          // Return the task (already 500 chars from template)
          return task.trim();
        }
      }

      // Fallback if day not found
      return 'Day $day: Complete today\'s challenge task.';
    } catch (e) {
      print('ChallengeService: Error extracting task - $e');
      return 'Day $day: Complete today\'s challenge task.';
    }
  }

  Future<String?> generateSummary({
    required String dailyTask,
    required String reflection,
    required String emotion,
    required String oneSentence,
  }) async {
    try {
      final prompt = '''
Create a concise, powerful summary (max 500 characters) of this day's progress in the 30-Day CIO Ascent Challenge:

Task: $dailyTask
Emotion: $emotion
Key Insight: $oneSentence

Full Reflection:
$reflection

Guidelines:
- Write in second person ("You...")
- Be brutally honest and direct
- Highlight what was accomplished
- Call out any avoidance or excuses
- Maximum 500 characters
- No fluff, just raw truth

Summary:
''';

      // Use hybrid AI service (on-device → cloud → fallback)
      final summary = await _aiService.generateSummary(prompt);
      return summary;
    } catch (e) {
      print('ChallengeService: Error generating summary - $e');
      return null;
    }
  }

  Future<bool> startChallenge(String template) async {
    final now = DateTime.now().toIso8601String();
    await _database.saveChallengeConfig(
      template: template,
      isActive: true,
      startDate: now,
      currentDay: 1,
    );

    // Schedule daily challenge reminders
    await _notifications.scheduleChallengeReminder();

    return true;
  }

  Future<Map<String, dynamic>?> getChallengeStatus() async {
    final config = await _database.getChallengeConfig();
    if (config == null) return null;

    final isActive = config['isActive'] == 1;
    if (!isActive) return null;

    final currentDay = config['currentDay'] as int;
    final streak = await _database.getChallengeStreak();

    return {
      'currentDay': currentDay,
      'streak': streak,
      'template': config['template'],
      'startDate': config['startDate'],
    };
  }

  Future<void> completeDay({
    required int day,
    required String dailyTask,
    required String reflection,
    required String emotion,
    required String oneSentence,
  }) async {
    // Generate AI summary
    final aiSummary = await generateSummary(
      dailyTask: dailyTask,
      reflection: reflection,
      emotion: emotion,
      oneSentence: oneSentence,
    );

    // Save completion
    await _database.saveChallengeCompletion(
      day: day,
      dailyTask: dailyTask,
      reflection: reflection,
      emotion: emotion,
      oneSentence: oneSentence,
      aiSummary: aiSummary,
    );

    // Track KPI
    final streak = await _database.getChallengeStreak();
    await _kpiTracking.trackChallengeCompletion(day, streak);

    // Sync challenge completion to GitHub as markdown
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _kpiTracking.syncChallengeCompletionToGitHub(
      day: day,
      date: today,
      dailyTask: dailyTask,
      reflection: reflection,
      emotion: emotion,
      oneSentence: oneSentence,
      aiSummary: aiSummary,
    );

    // Sync emotion to GitHub
    await _kpiTracking.syncDailyEmotionToGitHub(
      date: today,
      emotion: emotion,
      source: 'challenge',
      context: 'Day $day of 30-Day Challenge',
    );

    // Show completion notification
    await _notifications.showChallengeCompletedNotification(day);

    // Day 25 special reminder
    if (day == 25) {
      await _notifications.showDay25ReminderNotification();
    }

    // Schedule tomorrow's reminder
    await _notifications.scheduleChallengeReminder();

    // Update current day
    if (day < 30) {
      await _database.updateChallengeDay(day + 1);
    }
  }

  Future<Map<String, dynamic>?> getTodayTask() async {
    final status = await getChallengeStatus();
    if (status == null) return null;

    final currentDay = status['currentDay'] as int;
    if (currentDay > 30) return null;

    // Check if already completed today
    final completion = await _database.getChallengeCompletionForDay(currentDay);
    if (completion != null) return null;

    // Extract daily task
    final template = status['template'] as String;
    final task = await extractDailyTask(template, currentDay);

    return {
      'day': currentDay,
      'task': task,
      'streak': status['streak'],
    };
  }
}
