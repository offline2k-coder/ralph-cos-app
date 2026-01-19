import 'package:flutter/material.dart';
import '../services/challenge_service.dart';
import '../services/database_service.dart';
import '../widgets/tactical_card.dart';
import '../widgets/tactical_button.dart';
import '../widgets/status_badge.dart';
import 'settings_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _challengeService = ChallengeService();
  final _db = DatabaseService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _todayTask;

  // Simple 4 emotions
  final List<Map<String, String>> _emotions = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '💀', 'label': 'Dead'},
    {'emoji': '😰', 'label': 'Desperated'},
  ];

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
  }

  Future<void> _loadChallengeData() async {
    setState(() => _isLoading = true);

    final task = await _challengeService.getTodayTask();

    setState(() {
      _todayTask = task;
      _isLoading = false;
    });
  }

  Future<void> _completeWithEmotion(String emoji, String label) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final day = _todayTask!['day'] as int;
      final task = _todayTask!['task'] as String;

      await _challengeService.completeDay(
        day: day,
        dailyTask: task,
        reflection: '', // No text input needed
        emotion: '$emoji $label',
        oneSentence: '', // No text input needed
      );

      setState(() => _isSubmitting = false);

      _showMessage('Day $day completed!', isError: false);

      // Show reminder at day 25
      if (day == 25) {
        _showDay25Reminder();
      }

      // Reload data
      await _loadChallengeData();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showMessage('Error: $e', isError: true);
    }
  }

  void _showDay25Reminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('DAY 25 MILESTONE!'),
          ],
        ),
        content: const Text(
          '5 days left! You\'re in the final stretch.\n\nTime to design your NEXT 30-day challenge. Don\'t wait - momentum dies in the gap.\n\nWhat mountain are you climbing next?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'M FINISHING STRONG'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            '30-DAY CIO ASCENT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }

    if (_todayTask == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            '30-DAY CIO ASCENT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: Colors.deepOrange.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Active Challenge',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Start the 30-Day CIO Ascent Challenge to begin your transformation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TacticalButton(
                  onPressed: () async {
                    Navigator.pop(context); // Go back to dashboard
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    _loadChallengeData();
                  },
                  label: 'START CHALLENGE',
                  icon: Icons.play_arrow,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final day = _todayTask!['day'] as int;
    final task = _todayTask!['task'] as String;
    final streak = _todayTask!['streak'] as int;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          '30-DAY CIO ASCENT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day and Streak Tactical Card
            TacticalCard(
              title: 'CHALLENGE PROGRESS',
              icon: Icons.emoji_events,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'DAY',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$day/30',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade300,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.grey.shade700,
                  ),
                  Column(
                    children: [
                      const Text(
                        'STREAK',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade400,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TacticalCard(
              title: 'TODAY\'S OBJECTIVE',
              accentColor: Colors.blue.shade300,
              icon: Icons.center_focus_strong,
              child: Text(
                task,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
              ),
            ),
            const SizedBox(height: 40),

            Text(
              'CHECK-IN WITH EMOTION',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Four Emoji Buttons in 2x2 grid
            Row(
              children: [
                _buildEmotionOption(_emotions[0]),
                const SizedBox(width: 12),
                _buildEmotionOption(_emotions[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildEmotionOption(_emotions[2]),
                const SizedBox(width: 12),
                _buildEmotionOption(_emotions[3]),
              ],
            ),
            const SizedBox(height: 24),

            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionOption(Map<String, String> emotion) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting
            ? null
            : () => _completeWithEmotion(
                  emotion['emoji']!,
                  emotion['label']!,
                ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: Text(
                emotion['emoji']!,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emotion['label']!.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
