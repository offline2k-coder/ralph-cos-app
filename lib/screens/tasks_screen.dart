import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/status_badge.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DatabaseService _db = DatabaseService();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  String _selectedCategory = 'ALL';
  bool _isLoading = true;

  final List<String> _categories = [
    'ALL',
    '00_INBOX',
    '10_CORE_TASKS',
    '20_STRATEGIC_PROJECT',
    '30_KNOWLEDGE_ASSETS',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _db.getTasks();
    setState(() {
      _allTasks = tasks;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_selectedCategory == 'ALL') {
      _filteredTasks = _allTasks;
    } else {
      _filteredTasks = _allTasks
          .where((task) => task.category == _selectedCategory)
          .toList();
    }
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        _applyFilter();
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '00_INBOX':
        return Colors.red.shade700;
      case '10_CORE_TASKS':
        return Colors.orange.shade700;
      case '20_STRATEGIC_PROJECT':
        return Colors.blue.shade700;
      case '30_KNOWLEDGE_ASSETS':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getCategoryLabel(String category) {
    if (category == 'ALL') return 'ALL TASKS';
    return category.replaceAll('_', ' ');
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await _db.updateTask(updatedTask);
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'TASKS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                const Text(
                  'FILTER:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: Colors.grey.shade800,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          category == 'ALL' ? 'ALL TASKS' : _getCategoryLabel(category),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: _onCategoryChanged,
                  ),
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sync your Notion backup in Settings',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        color: Colors.deepOrange,
                        child: ListView.builder(
                          itemCount: _filteredTasks.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return Card(
                              color: Colors.grey.shade900,
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task.isCompleted,
                                  onChanged: (_) => _toggleTaskCompletion(task),
                                  activeColor: Colors.green,
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? Colors.grey
                                        : Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      StatusBadge(
                                        label: _getCategoryLabel(task.category),
                                        color: _getCategoryColor(task.category),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskDetailScreen(task: task),
                                    ),
                                  ).then((_) => _loadTasks());
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
