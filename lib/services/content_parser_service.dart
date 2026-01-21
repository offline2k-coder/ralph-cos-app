import 'dart:io';
import '../models/task.dart';
import 'git_sync_service.dart';

class ContentParserService {
  static final ContentParserService _instance = ContentParserService._internal();
  factory ContentParserService() => _instance;
  ContentParserService._internal();

  final _gitSync = GitSyncService();

  Future<List<Task>> parseAllContent() async {
    final tasks = <Task>[];

    // Parse markdown files
    final mdFiles = await _gitSync.getMarkdownFiles();
    for (var file in mdFiles) {
      if (file is File) {
        final task = await _parseMarkdownFile(file);
        if (task != null) tasks.add(task);
      }
    }

    return tasks;
  }

  Future<Task?> _parseMarkdownFile(File file) async {
    try {
      final content = await file.readAsString();
      final fileName = file.path.split('/').last;
      final title = fileName.replaceAll('.md', '');
      final category = await _gitSync.getCategory(file.path);

      // Check for completed checkboxes
      final hasCheckedBoxes = content.contains('- [x]') || content.contains('- [X]');
      final hasUncheckedBoxes = content.contains('- [ ]');

      // Consider task complete if all checkboxes are checked (or no checkboxes)
      final isCompleted = hasCheckedBoxes && !hasUncheckedBoxes;

      return Task(
        id: file.path,
        title: title,
        content: content,
        category: category,
        isCompleted: isCompleted,
        createdAt: file.statSync().modified,
      );
    } catch (e) {
      print('ContentParser: Error parsing file ${file.path} - $e');
      return null;
    }
  }

  bool hasCheckboxes(String content) {
    return content.contains('- [ ]') ||
           content.contains('- [x]') ||
           content.contains('- [X]');
  }

  int countTotalCheckboxes(String content) {
    final unchecked = '- [ ]'.allMatches(content).length;
    final checked = '- [x]'.allMatches(content).length +
                    '- [X]'.allMatches(content).length;
    return unchecked + checked;
  }

  int countCheckedCheckboxes(String content) {
    return '- [x]'.allMatches(content).length +
           '- [X]'.allMatches(content).length;
  }

  Future<void> writeTaskBack(Task task) async {
    try {
      final file = File(task.id); // task.id is the file path
      if (!await file.exists()) return;

      String content = await file.readAsString();
      
      if (task.isCompleted) {
        // Mark all unchecked as checked or just ensure it looks checked
        // If it's a simple task file (no sub-tasks), we just replace the first match or overall
        // If it has multiple boxes, a "brutal" approach is to check them all if the task is complete
        content = content.replaceAll('- [ ]', '- [x]');
      } else {
        // Uncheck all
        content = content.replaceAll('- [x]', '- [ ]');
        content = content.replaceAll('- [X]', '- [ ]');
      }

      await file.writeAsString(content);
      
      // Trigger Git Sync
      await _gitSync.sync();
    } catch (e) {
      print('ContentParser: Error writing task back - $e');
    }
  }
}
