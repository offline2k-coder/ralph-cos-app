import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/tactical_card.dart';
import '../widgets/tactical_button.dart';
import '../core/app_constants.dart';

class SundayRitualScreen extends StatefulWidget {
  const SundayRitualScreen({super.key});

  @override
  State<SundayRitualScreen> createState() => _SundayRitualScreenState();
}

class _SundayRitualScreenState extends State<SundayRitualScreen> {
  final DatabaseService _db = DatabaseService();
  List<Task> _weekTasks = [];
  bool _isLoading = true;
  bool _allTasksComplete = false;

  final List<String> _weeklyReflections = [
    'What was your biggest win this week?',
    'What challenge did you overcome?',
    'What did you avoid or procrastinate on?',
    'What one thing would make next week great?',
    'Who is your enemy this week? (Fear, distraction, comfort?)',
  ];

  @override
  void initState() {
    super.initState();
    _loadWeekTasks();
  }

  Future<void> _loadWeekTasks() async {
    setState(() => _isLoading = true);

    final allTasks = await _db.getTasks();

    // Get tasks from CORE_TASKS and STRATEGIC_PROJECT
    final weekTasks = allTasks.where((task) {
      return task.category == '10_CORE_TASKS' ||
             task.category == '20_STRATEGIC_PROJECT';
    }).toList();

    final allComplete = weekTasks.isNotEmpty &&
                       weekTasks.every((task) => task.isCompleted);

    setState(() {
      _weekTasks = weekTasks;
      _allTasksComplete = allComplete;
      _isLoading = false;
    });
  }

  bool get _isSundayRitualActive {
    final now = DateTime.now();
    return now.weekday == DateTime.sunday &&
           now.hour >= AppConstants.sundayStrategicStartHour &&
           now.hour < AppConstants.sundayStrategicEndHour;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'SUNDAY RITUAL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Tactical Card
                  TacticalCard(
                    title: _isSundayRitualActive ? 'RITUAL ACTIVE' : 'RITUAL LOCKED',
                    accentColor: _isSundayRitualActive ? Colors.green : Colors.orange,
                    icon: _isSundayRitualActive ? Icons.check_circle : Icons.schedule,
                    child: Text(
                      _isSundayRitualActive
                          ? 'Available until ${AppConstants.sundayStrategicEndHour}:00'
                          : 'Available Sunday ${AppConstants.sundayStrategicStartHour}:00–${AppConstants.sundayStrategicEndHour}:00',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Week Progress
                  TacticalCard(
                    title: 'WEEK PROGRESS',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${_weekTasks.where((t) => t.isCompleted).length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                ),
                                const Text('COMPLETED'),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 60,
                              color: Colors.grey.shade700,
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_weekTasks.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const Text('TOTAL'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _weekTasks.isEmpty
                              ? 0
                              : _weekTasks.where((t) => t.isCompleted).length /
                                  _weekTasks.length,
                          backgroundColor: Colors.grey.shade800,
                          color: _allTasksComplete
                              ? Colors.green
                              : Colors.orange,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 12),
                        if (_allTasksComplete)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.celebration,
                                  color: Colors.green.shade300, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ALL TASKS COMPLETE!',
                                style: TextStyle(
                                  color: Colors.green.shade300,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Keep pushing to complete your weekly goals',
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Reflections
                  const SizedBox(height: 12),
                  if (_isSundayRitualActive)
                    ..._weeklyReflections.map((question) {
                      return TacticalCard(
                        title: 'REFLECTION',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Your answer...',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  else
                    TacticalCard(
                      title: 'RITUAL LOCKED',
                      icon: Icons.lock,
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              'Only available Sunday ${AppConstants.sundayStrategicStartHour}:00–${AppConstants.sundayStrategicEndHour}:00',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Next Week Planning
                  if (_isSundayRitualActive)
                    TacticalCard(
                      title: 'NEXT WEEK PLANNING',
                      accentColor: Colors.deepOrange.shade300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set your top 3 priorities for next week:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(3, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Priority ${index + 1}',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade800,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          TacticalButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Week plan saved!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            label: 'SAVE WEEK PLAN',
                            icon: Icons.save,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
