import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/sunday_ritual_screen.dart';
import 'screens/challenge_screen.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/git_sync_service.dart';
import 'services/content_parser_service.dart';
import 'services/notification_service.dart';
import 'services/daily_prompt_service.dart';
import 'services/mantra_service.dart';
import 'services/kpi_tracking_service.dart';
import 'services/background_sync_service.dart';
import 'services/challenge_service.dart';
import 'models/streak_data.dart';
import 'models/task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.scheduleMorningPush();
    await notificationService.scheduleEveningRitualReminder();
    await notificationService.scheduleSundayStrategicReminder();
    // Challenge reminders scheduled when challenge starts
  } catch (e) {
    print('Notification setup failed: $e');
    // Continue without notifications
  }

  // Initialize background sync
  try {
    await BackgroundSyncService().initialize();
    await BackgroundSyncService().scheduleNightSync();
  } catch (e) {
    print('Background sync setup failed: $e');
    // Continue without background sync
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BiometricLoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.military_tech,
              size: 120,
              color: Colors.deepOrange.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              'RALPH',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chief of Staff',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.deepOrange.shade300,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }
}

// BIOMETRIC LOGIN SCREEN
class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _authStatus = 'Not authenticated';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Authenticating...';
    });

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Ralph demands authentication. No excuses.',
        biometricOnly: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authStatus = 'Error: $e';
        _isAuthenticating = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _authStatus = authenticated ? 'Authenticated' : 'Failed';
    });

    if (authenticated && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 100,
                color: Colors.deepOrange.shade700,
              ),
              const SizedBox(height: 32),
              Text(
                'BIOMETRIC LOGIN',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Required. No exceptions.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isAuthenticating)
                const CircularProgressIndicator(
                  color: Colors.deepOrange,
                )
              else
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('AUTHENTICATE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _authStatus,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _authStatus == 'Authenticated'
                          ? Colors.green
                          : Colors.red,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// DASHBOARD SCREEN
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
    return hour >= 5 && hour < 9;
  }

  bool get _isMorningVowTime {
    final hour = _currentTime.hour;
    return hour >= 5 && hour < 10;
  }

  bool get _isEveningRitualTime {
    final hour = _currentTime.hour;
    return hour >= 17;
  }

  bool get _isSundayStrategicTime {
    final weekday = _currentTime.weekday;
    final hour = _currentTime.hour;
    return weekday == DateTime.sunday && hour >= 15 && hour < 22;
  }

  Future<void> _handleCheckIn() async {
    final oldStreak = _streakData?.currentStreak ?? 0;

    await _db.checkIn();
    await _loadData();

    final newStreak = _streakData?.currentStreak ?? 0;

    // Track check-in KPI
    await _kpiTracking.trackDailyCheckIn();

    // Check if pass was earned
    if (newStreak % 20 == 0 && newStreak > oldStreak) {
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

  Widget _buildChecklist(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '▪ ',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
                    // Happy
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _completeEveningRitual('😊', 'Happy'),
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
                              child: const Text(
                                '😊',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'HAPPY',
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
                    ),
                    const SizedBox(width: 8),
                    // Sad
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _completeEveningRitual('😢', 'Sad'),
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
                              child: const Text(
                                '😢',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SAD',
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Dead
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _completeEveningRitual('💀', 'Dead'),
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
                              child: const Text(
                                '💀',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DEAD',
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
                    ),
                    const SizedBox(width: 8),
                    // Desperated
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _completeEveningRitual('😰', 'Desperated'),
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
                              child: const Text(
                                '😰',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DESPERATED',
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
                    ),
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
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            const Text(
              'RALPH-CoS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            if (_isSyncing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                ),
              ),
            ],
          ],
        ),
        actions: [
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
      drawer: Drawer(
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
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('30-Day Challenge'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengeScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Sunday Ritual'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SundayRitualScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _loadData();
              },
            ),
          ],
        ),
      ),
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
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isCheckInActive
                      ? 'CHECK-IN WINDOW ACTIVE'
                      : 'Check-in: 05:00–09:00',
                  style: TextStyle(
                    color: _isCheckInActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // DAILY STATUS CARD
              Card(
                color: Colors.grey.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY\'S STATUS',
                        style: TextStyle(
                          color: Colors.deepOrange.shade300,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(
                                _morningCheckInDone
                                    ? Icons.check_circle
                                    : Icons.pending_outlined,
                                color: _morningCheckInDone
                                    ? Colors.green
                                    : Colors.grey.shade600,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CHECK-IN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _morningCheckInDone
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(
                                _challengeDone
                                    ? Icons.check_circle
                                    : Icons.pending_outlined,
                                color: _challengeDone
                                    ? Colors.green
                                    : Colors.grey.shade600,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CHALLENGE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _challengeDone
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(
                                _eveningRitualDone
                                    ? Icons.check_circle
                                    : Icons.pending_outlined,
                                color: _eveningRitualDone
                                    ? Colors.green
                                    : Colors.grey.shade600,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'EVENING',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _eveningRitualDone
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SUNDAY STRATEGIC RESET REMINDER
              if (_isSundayStrategicTime)
                Card(
                  color: Colors.red.shade900.withValues(alpha: 0.6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.red.shade300,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'SUNDAY STRATEGIC RESET (15:00-22:00)',
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildChecklist([
                          'Review last week: What worked? What failed?',
                          'Check Anti-Vision: Am I drifting toward Game Over?',
                          'Set 3 non-negotiable priorities for this week',
                          'Review 30-Day Challenge progress',
                          'Update task lists and close open loops',
                        ]),
                      ],
                    ),
                  ),
                ),
              if (_isSundayStrategicTime) const SizedBox(height: 16),

              // MORNING VOW REMINDER
              if (_isMorningVowTime && !_isSundayStrategicTime)
                Card(
                  color: Colors.red.shade900.withValues(alpha: 0.6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: Colors.red.shade300,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'THE VOW (05:00-10:00)',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_dailyMantra != null) ...[
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
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildChecklist([
                          'What am I avoiding right now?',
                          'What would I do if I weren\'t afraid?',
                          'What\'s the ONE thing that makes today matter?',
                          'Complete daily check-in (05:00-09:00)',
                          'Work on 30-Day Challenge task',
                        ]),
                      ],
                    ),
                  ),
                ),
              if (_isMorningVowTime && !_isSundayStrategicTime) const SizedBox(height: 16),

              // EVENING ZERO-CHECK REMINDER
              if (_isEveningRitualTime && !_isSundayStrategicTime)
                Card(
                  color: Colors.red.shade900.withValues(alpha: 0.6),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.nightlight,
                              color: Colors.red.shade300,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ZERO-CHECK + RITUAL (17:00+)',
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_dailyMantra != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Mantra:',
                                  style: TextStyle(
                                    color: Colors.red.shade200,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"$_dailyMantra"',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildChecklist([
                          'Did I keep today\'s vow?',
                          'What did I avoid today?',
                          'Inbox Zero: Process all messages and tasks',
                          'Task Zero: Complete or reschedule everything',
                          'Guilt Zero: Forgive or fix what\'s weighing on me',
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showEveningFeedbackDialog(),
                            icon: const Icon(Icons.check_circle_outline, size: 20),
                            label: const Text('COMPLETE EVENING RITUAL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isEveningRitualTime && !_isSundayStrategicTime) const SizedBox(height: 16),

              // STREAK & PASSES CARD
              Card(
                color: Colors.grey.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 60,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${streak.currentStreak}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                          ),
                          const Text('STREAK'),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 80,
                        color: Colors.grey.shade700,
                      ),
                      Column(
                        children: [
                          Icon(
                            Icons.shield,
                            size: 60,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${streak.passesAvailable}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade400,
                                ),
                          ),
                          const Text('PASSES'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // CHECK-IN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCheckInActive ? _handleCheckIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(
                    _isCheckInActive ? 'CHECK IN NOW' : 'CHECK-IN LOCKED',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // DAILY FOCUS TASK CARD
              if (_focusTask != null)
                Card(
                  color: Colors.blue.shade900.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.center_focus_strong,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'DAILY FOCUS',
                                style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
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
                        ),
                        const SizedBox(height: 12),
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
                ),
              if (_focusTask != null) const SizedBox(height: 24),

              // DAILY MANTRA CARD (DAN KOE)
              if (_dailyMantra != null)
                Card(
                  color: Colors.red.shade900.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TODAY\'S MANTRA',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                ),
              if (_dailyMantra != null) const SizedBox(height: 24),

              // LIFE CHALLENGE PROMPT CARD
              Card(
                color: Colors.deepOrange.shade900.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Colors.deepOrange.shade300,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DAILY CHALLENGE',
                            style: TextStyle(
                              color: Colors.deepOrange.shade300,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
