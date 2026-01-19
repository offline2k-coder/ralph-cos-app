import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../models/streak_data.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/git_sync_service.dart';
import '../services/content_parser_service.dart';
import '../services/daily_prompt_service.dart';
import '../services/notification_service.dart';
import '../services/mantra_service.dart';
import '../services/kpi_tracking_service.dart';
import '../services/challenge_service.dart';
import '../widgets/tactical_card.dart';
import '../widgets/tactical_button.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'challenge_screen.dart';
import 'sunday_ritual_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final SecureStorageService _storage = SecureStorageService();
  final GitSyncService _gitSync = GitSyncService();
  final ContentParserService _parser = ContentParserService();
  final DailyPromptService _promptService = DailyPromptService();
  final NotificationService _notificationService = NotificationService();
  final MantraService _mantraService = MantraService();
  final KpiTrackingService _kpiTracking = KpiTrackingService();
  final ChallengeService _challengeService = ChallengeService();

  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  StreakData? _streakData;
  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, String> _dailyPrompt = {};
  String? _dailyMantra;
  Task? _focusTask;

  // Daily completion status
  bool _morningCheckInDone = false;
  bool _challengeDone = false;
  bool _eveningRitualDone = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _dailyPrompt = _promptService.getDailyPrompt();
    _loadData();
  }

  Future<void> _checkDailyCompletion() async {
    final now = DateTime.now();

    // Check morning check-in
    final streak = await _db.getStreakData();
    final morningDone = streak != null &&
        streak.lastCheckIn.year == now.year &&
        streak.lastCheckIn.month == now.month &&
        streak.lastCheckIn.day == now.day;

    // Check 30-day challenge
    final challengeStatus = await _challengeService.getChallengeStatus();
    bool challengeDone = false;
    if (challengeStatus != null) {
      final currentDay = challengeStatus['currentDay'] as int;
      final completion = await _db.getChallengeCompletionForDay(currentDay);
      challengeDone = completion != null;
    }

    // Check evening ritual
    final eveningReflection = await _db.getTodayEveningReflection();
    final eveningDone = eveningReflection != null;

    setState(() {
      _morningCheckInDone = morningDone;
      _challengeDone = challengeDone;
      _eveningRitualDone = eveningDone;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load streak data
    final streak = await _db.getStreakData();

    // Load daily mantra
    final mantra = await _mantraService.getTodayMantra();

    // Load focus task (newest from INBOX or KNOWLEDGE_ASSETS)
    Task? focusTask;
    final inboxTasks = await _db.getTasksByCategory('00_INBOX');
    final knowledgeTasks = await _db.getTasksByCategory('30_KNOWLEDGE_ASSETS');

    final allFocusTasks = [...inboxTasks, ...knowledgeTasks];
    if (allFocusTasks.isNotEmpty) {
      // Sort by createdAt descending to get newest
      allFocusTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      focusTask = allFocusTasks.first;
    }

    setState(() {
      _streakData = streak;
      _dailyMantra = mantra;
      _focusTask = focusTask;
      _isLoading = false;
    });

    // Check daily completion status
    await _checkDailyCompletion();

    // Auto-sync if credentials exist
    if (await _storage.hasGitHubCredentials()) {
      _syncInBackground();
    }
  }

  Future<void> _syncInBackground() async {
    setState(() => _isSyncing = true);

    final success = await _gitSync.cloneOrPullRepo();
    if (success) {
      final tasks = await _parser.parseAllContent();
      await _db.clearAllTasks();
      await _db.insertTasks(tasks);
    }

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool get _isCheckInActive {
    final hour = _currentTime.hour;
    return hour >= AppConstants.checkInStartHour && hour < AppConstants.checkInEndHour;
  }

  bool get _isMorningVowTime {
    final hour = _currentTime.hour;
    return hour >= AppConstants.checkInStartHour && hour < AppConstants.morningVowEndHour;
  }

  bool get _isEveningRitualTime {
    final hour = _currentTime.hour;
    return hour >= AppConstants.eveningRitualStartHour;
  }

  bool get _isSundayStrategicTime {
    final weekday = _currentTime.weekday;
    final hour = _currentTime.hour;
    return weekday == DateTime.sunday && 
           hour >= AppConstants.sundayStrategicStartHour && 
           hour < AppConstants.sundayStrategicEndHour;
  }

  Future<void> _handleCheckIn() async {
    final oldStreak = _streakData?.currentStreak ?? 0;

    await _db.checkIn();
    await _loadData();

    final newStreak = _streakData?.currentStreak ?? 0;

    // Track check-in KPI
    await _kpiTracking.trackDailyCheckIn();

    // Check if pass was earned
    if (newStreak % AppConstants.daysPerPass == 0 && newStreak > oldStreak) {
      await _notificationService.showPassEarnedNotification();
      await _kpiTracking.trackPassEarned(_streakData?.passesAvailable ?? 0);
    }

    // Check if streak broke
    if (newStreak < oldStreak) {
      await _kpiTracking.trackStreakBreak(oldStreak);
    }

    // Update completion status
    await _checkDailyCompletion();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in recorded! Streak updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showEveningFeedbackDialog() async {
    // Check if already completed today
    final existing = await _db.getTodayEveningReflection();
    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evening ritual already completed today!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Evening Ritual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_dailyMantra != null) ...[
              Text(
                'Today\'s Mantra:',
                style: TextStyle(
                  color: Colors.deepOrange.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$_dailyMantra"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'HOW DO YOU FEEL?',
              style: TextStyle(
                color: Colors.deepOrange.shade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Four emotion buttons in 2x2 grid
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEmotionButton('😊', 'HAPPY'),
                    const SizedBox(width: 8),
                    _buildEmotionButton('😢', 'SAD'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEmotionButton('💀', 'DEAD'),
                    const SizedBox(width: 8),
                    _buildEmotionButton('😰', 'DESPERATED'),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionButton(String emoji, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _completeEveningRitual(emoji, label[0] + label.substring(1).toLowerCase()),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeEveningRitual(String emoji, String label) async {
    Navigator.pop(context); // Close dialog immediately

    // Save evening reflection with emotion
    await _db.saveEveningReflection(
      mantra: _dailyMantra ?? '',
      keptVow: false,
      whatAvoided: '$emoji $label',
      inboxZero: false,
      taskZero: false,
      guiltZero: false,
      reflection: null,
    );

    // Track evening reflection KPI
    await _kpiTracking.trackEveningReflection(
      keptVow: false,
      inboxZero: false,
      taskZero: false,
      guiltZero: false,
    );

    // Sync evening reflection to GitHub as markdown
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _kpiTracking.syncEveningReflectionToGitHub(
      date: today,
      mantra: _dailyMantra ?? '',
      keptVow: false,
      whatAvoided: '$emoji $label',
      inboxZero: false,
      taskZero: false,
      guiltZero: false,
      reflection: null,
    );

    // Sync emotion to GitHub
    await _kpiTracking.syncDailyEmotionToGitHub(
      date: today,
      emotion: '$emoji $label',
      source: 'evening_ritual',
      context: 'Evening reflection',
    );

    // Reload data to update status
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evening ritual completed! Feeling: $emoji $label'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    final streak = _streakData;
    if (streak == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Error loading data'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('RALPH-CoS'),
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TIME DISPLAY
              Center(
                child: Text(
                  '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isCheckInActive
                      ? 'CHECK-IN WINDOW ACTIVE'
                      : 'Check-in: ${AppConstants.checkInStartHour.toString().padLeft(2, '0')}:00–${AppConstants.checkInEndHour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    color: _isCheckInActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // DAILY STATUS CARD
              TacticalCard(
                title: 'TODAY\'S STATUS',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusIndicator('CHECK-IN', _morningCheckInDone),
                    _buildStatusIndicator('CHALLENGE', _challengeDone),
                    _buildStatusIndicator('EVENING', _eveningRitualDone),
                  ],
                ),
              ),

              // SUNDAY STRATEGIC RESET REMINDER
              if (_isSundayStrategicTime)
                TacticalCard(
                  title: 'SUNDAY STRATEGIC RESET (${AppConstants.sundayStrategicStartHour}:00-${AppConstants.sundayStrategicEndHour}:00)',
                  accentColor: Colors.red.shade300,
                  icon: Icons.calendar_today,
                  actions: const [
                     Icon(Icons.warning, color: Colors.red, size: 20),
                  ],
                  child: const TacticalChecklist(
                    items: [
                      'Review last week: What worked? What failed?',
                      'Check Anti-Vision: Am I drifting toward Game Over?',
                      'Set 3 non-negotiable priorities for this week',
                      'Review 30-Day Challenge progress',
                      'Update task lists and close open loops',
                    ],
                  ),
                ),

              // MORNING VOW REMINDER
              if (_isMorningVowTime && !_isSundayStrategicTime)
                TacticalCard(
                  title: 'THE VOW (${AppConstants.checkInStartHour.toString().padLeft(2, '0')}:00-${AppConstants.morningVowEndHour}:00)',
                  accentColor: Colors.red.shade300,
                  icon: Icons.wb_sunny,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_dailyMantra != null) ...[
                        _buildMantraBubble(_dailyMantra!),
                        const SizedBox(height: 12),
                      ],
                      const TacticalChecklist(
                        items: [
                          'What am I avoiding right now?',
                          'What would I do if I weren\'t afraid?',
                          'What\'s the ONE thing that makes today matter?',
                          'Complete daily check-in (05:00-09:00)',
                          'Work on 30-Day Challenge task',
                        ],
                      ),
                    ],
                  ),
                ),

              // EVENING ZERO-CHECK REMINDER
              if (_isEveningRitualTime && !_isSundayStrategicTime)
                TacticalCard(
                  title: 'ZERO-CHECK + RITUAL (${AppConstants.eveningRitualStartHour}:00+)',
                  accentColor: Colors.red.shade300,
                  icon: Icons.nightlight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_dailyMantra != null) ...[
                        _buildMantraBubble(_dailyMantra!, title: 'Today\'s Mantra:'),
                        const SizedBox(height: 12),
                      ],
                      const TacticalChecklist(
                        items: [
                          'Did I keep today\'s vow?',
                          'What did I avoid today?',
                          'Inbox Zero: Process all messages and tasks',
                          'Task Zero: Complete or reschedule everything',
                          'Guilt Zero: Forgive or fix what\'s weighing on me',
                        ],
                      ),
                      const SizedBox(height: 12),
                      TacticalButton(
                        onPressed: _showEveningFeedbackDialog,
                        label: 'COMPLETE EVENING RITUAL',
                        icon: Icons.check_circle_outline,
                        backgroundColor: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // STREAK & PASSES CARD
              _buildStreakPassesCard(streak),
              const SizedBox(height: 16),

              // CHECK-IN BUTTON
              TacticalButton(
                onPressed: _isCheckInActive ? _handleCheckIn : null,
                label: _isCheckInActive ? 'CHECK IN NOW' : 'CHECK-IN LOCKED',
                isLoading: false,
              ),

              const SizedBox(height: 24),

              // DAILY FOCUS TASK CARD
              if (_focusTask != null)
                TacticalCard(
                  title: 'DAILY FOCUS',
                  accentColor: Colors.blue.shade300,
                  icon: Icons.center_focus_strong,
                  actions: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _focusTask!.category.replaceAll('_', ' '),
                        style: TextStyle(
                          color: Colors.blue.shade200,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _focusTask!.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Newest from ${_focusTask!.category.contains("INBOX") ? "Inbox" : "Knowledge Assets"}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),

              // DAILY MANTRA CARD
              if (_dailyMantra != null)
                TacticalCard(
                  title: 'TODAY\'S MANTRA',
                  accentColor: Colors.red.shade300,
                  icon: Icons.format_quote,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dailyMantra!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on Dan Koe\'s philosophy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),

              // DAILY CHALLENGE PROMPT CARD
              TacticalCard(
                title: 'DAILY CHALLENGE',
                icon: Icons.psychology,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dailyPrompt['question'] ?? 'What are you avoiding right now?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dailyPrompt['action'] ?? 'Face it. Name it. Own it.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade900,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.military_tech,
                  size: 48,
                  color: Colors.deepOrange.shade300,
                ),
                const SizedBox(height: 8),
                const Text(
                  'RALPH',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'Chief of Staff',
                  style: TextStyle(
                    color: Colors.deepOrange.shade300,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerTile(Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
          _buildDrawerTile(Icons.task_alt, 'Tasks', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
          }),
          _buildDrawerTile(Icons.emoji_events, '30-Day Challenge', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()));
          }),
          _buildDrawerTile(Icons.event_note, 'Sunday Ritual', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SundayRitualScreen()));
          }),
          const Divider(),
          _buildDrawerTile(Icons.settings, 'Settings', () async {
            Navigator.pop(context);
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            _loadData();
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildStatusIndicator(String label, bool isDone) {
    final color = isDone ? Colors.green : Colors.grey.shade600;
    return Column(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.pending_outlined,
          color: color,
          size: 40,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMantraBubble(String mantra, {String? title}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                color: Colors.red.shade200,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '"$mantra"',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPassesCard(StreakData streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(Icons.local_fire_department, '${streak.currentStreak}', 'STREAK', Colors.orange.shade700),
            Container(
              width: 1,
              height: 80,
              color: Colors.grey.shade700,
            ),
            _buildMetricItem(Icons.shield, '${streak.passesAvailable}', 'PASSES', Colors.blue.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 60, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(label),
      ],
    );
  }
}
