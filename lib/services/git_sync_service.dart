import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'secure_storage_service.dart';

class GitSyncService {
  static final GitSyncService _instance = GitSyncService._internal();
  factory GitSyncService() => _instance;
  GitSyncService._internal();

  final _storage = SecureStorageService();
  String? _repoPath;

  Future<String> get repoPath async {
    if (_repoPath != null) return _repoPath!;
    final appDir = await getApplicationDocumentsDirectory();
    _repoPath = '${appDir.path}/my-notion-backup';
    return _repoPath!;
  }

  Future<bool> _runGit(List<String> args, {String? workingDir}) async {
    try {
      final result = await Process.run('git', args, workingDirectory: workingDir);
      if (result.exitCode != 0) {
        print('Git Error: ${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      print('Git Process Error: $e');
      return false;
    }
  }

  Future<bool> sync() async {
    try {
      final token = await _storage.getGitHubToken();
      final username = await _storage.getGitHubUsername();
      if (token == null || username == null) return false;

      final path = await repoPath;
      final dir = Directory(path);
      final remoteUrl = 'https://$token@github.com/offline2k-coder/my-notion-backup.git';

      if (!await dir.exists()) {
        // Initial Clone
        await dir.parent.create(recursive: true);
        final success = await _runGit(['clone', remoteUrl, path]);
        if (!success) return false;
      }

      // 1. Pull --rebase (Single Source of Truth)
      bool pullSuccess = await _runGit(['pull', '--rebase', 'origin', 'main'], workingDir: path);
      if (!pullSuccess) return false;

      // 2. Add local changes
      await _runGit(['add', '.'], workingDir: path);

      // 3. Commit
      final now = DateTime.now().toIso8601String();
      await _runGit(['commit', '-m', 'Ralph-CoS Sync: $now'], workingDir: path);

      // 4. Push
      return await _runGit(['push', 'origin', 'main'], workingDir: path);
    } catch (e) {
      print('GitSyncService Sync Error: $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> getMarkdownFiles() async {
    try {
      final path = await repoPath;
      final dir = Directory(path);
      if (!await dir.exists()) return [];

      final List<FileSystemEntity> mdFiles = [];
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.md')) {
          mdFiles.add(entity);
        }
      }

      mdFiles.sort((a, b) {
        final aPriority = _getFolderPriority(a.path);
        final bPriority = _getFolderPriority(b.path);
        return aPriority.compareTo(bPriority);
      });

      return mdFiles;
    } catch (e) {
      print('Error getting markdown files: $e');
      return [];
    }
  }

  int _getFolderPriority(String path) {
    if (path.contains('00_INBOX')) return 0;
    if (path.contains('10_CORE_TASKS')) return 1;
    if (path.contains('20_STRATEGIC_PROJECT')) return 2;
    if (path.contains('30_KNOWLEDGE_ASSETS')) return 3;
    return 999;
  }

  Future<String> getCategory(String path) async {
    if (path.contains('00_INBOX')) return '00_INBOX';
    if (path.contains('10_CORE_TASKS')) return '10_CORE_TASKS';
    if (path.contains('20_STRATEGIC_PROJECT')) return '20_STRATEGIC_PROJECT';
    if (path.contains('30_KNOWLEDGE_ASSETS')) return '30_KNOWLEDGE_ASSETS';
    return 'UNCATEGORIZED';
  }
}
