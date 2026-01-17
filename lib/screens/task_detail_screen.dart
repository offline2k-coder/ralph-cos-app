import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final DatabaseService _db = DatabaseService();
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
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
    switch (category) {
      case '00_INBOX':
        return 'INBOX';
      case '10_CORE_TASKS':
        return 'CORE TASKS';
      case '20_STRATEGIC_PROJECT':
        return 'STRATEGIC PROJECT';
      case '30_KNOWLEDGE_ASSETS':
        return 'KNOWLEDGE ASSETS';
      default:
        return category;
    }
  }

  Future<void> _toggleCompletion() async {
    final updatedTask = _task.copyWith(isCompleted: !_task.isCompleted);
    await _db.updateTask(updatedTask);
    setState(() {
      _task = updatedTask;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _task.isCompleted ? 'Task marked complete!' : 'Task marked incomplete',
          ),
          backgroundColor: _task.isCompleted ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'TASK DETAIL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: _task.isCompleted ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleCompletion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_task.category),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCategoryLabel(_task.category),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: _task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: _task.isCompleted ? Colors.grey : Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Created: ${_task.createdAt.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.grey.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.article,
                            color: Colors.deepOrange.shade300,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CONTENT',
                            style: TextStyle(
                              color: Colors.deepOrange.shade300,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarkdownBody(
                        data: _task.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.white, fontSize: 16),
                          h1: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          code: TextStyle(
                            backgroundColor: Colors.grey.shade800,
                            color: Colors.deepOrange.shade300,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          blockquote: TextStyle(
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                          listBullet: const TextStyle(color: Colors.deepOrange),
                          checkbox: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleCompletion,
        backgroundColor: _task.isCompleted
            ? Colors.orange.shade700
            : Colors.green.shade700,
        icon: Icon(_task.isCompleted ? Icons.undo : Icons.check),
        label: Text(_task.isCompleted ? 'MARK INCOMPLETE' : 'MARK COMPLETE'),
      ),
    );
  }
}
