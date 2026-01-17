import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
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

  Future<bool> cloneOrPullRepo() async {
    try {
      final token = await _storage.getGitHubToken();
      final username = await _storage.getGitHubUsername();

      if (token == null || username == null) {
        print('GitSyncService: No credentials found');
        return false;
      }

      final path = await repoPath;
      final dir = Directory(path);

      // Delete existing directory
      if (await dir.exists()) {
        print('GitSyncService: Removing old backup...');
        await dir.delete(recursive: true);
      }

      // Download repo as ZIP from GitHub API
      print('GitSyncService: Downloading repository...');
      final zipUrl = 'https://api.github.com/repos/offline2k-coder/my-notion-backup/zipball/main';

      final response = await http.get(
        Uri.parse(zipUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );

      if (response.statusCode != 200) {
        print('GitSyncService: Download failed with status ${response.statusCode}');
        return false;
      }

      print('GitSyncService: Extracting archive...');

      // Decode the ZIP
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);

      // Create directory
      await dir.create(recursive: true);

      // Extract files (skip the root folder created by GitHub)
      for (final file in archive) {
        final filename = file.name;

        // Skip the first directory level (GitHub adds repo-commit hash folder)
        final pathParts = filename.split('/');
        if (pathParts.length <= 1) continue;

        // Reconstruct path without first directory
        final relativePath = pathParts.sublist(1).join('/');
        if (relativePath.isEmpty) continue;

        final filePath = '$path/$relativePath';

        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      print('GitSyncService: Sync successful');
      return true;
    } catch (e) {
      print('GitSyncService: Error - $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> getMarkdownFiles() async {
    try {
      final path = await repoPath;
      final dir = Directory(path);

      if (!await dir.exists()) {
        print('GitSyncService: Repo not cloned yet');
        return [];
      }

      final List<FileSystemEntity> mdFiles = [];
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.md')) {
          mdFiles.add(entity);
        }
      }

      // Sort by priority folders
      mdFiles.sort((a, b) {
        final aPriority = _getFolderPriority(a.path);
        final bPriority = _getFolderPriority(b.path);
        return aPriority.compareTo(bPriority);
      });

      return mdFiles;
    } catch (e) {
      print('GitSyncService: Error getting markdown files - $e');
      return [];
    }
  }

  Future<List<FileSystemEntity>> getCsvFiles() async {
    try {
      final path = await repoPath;
      final dir = Directory(path);

      if (!await dir.exists()) {
        return [];
      }

      final List<FileSystemEntity> csvFiles = [];
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.csv')) {
          csvFiles.add(entity);
        }
      }

      return csvFiles;
    } catch (e) {
      print('GitSyncService: Error getting CSV files - $e');
      return [];
    }
  }

  int _getFolderPriority(String path) {
    if (path.contains('00_INBOX')) return 0;
    if (path.contains('10_CORE_TASKS')) return 1;
    if (path.contains('20_STRATEGIC_PROJECT')) return 2;
    if (path.contains('30_KNOWLEDGE_ASSETS')) return 3;
    return 999; // Unknown folders last
  }

  Future<String?> getToken() async {
    return await _storage.getGitHubToken();
  }

  Future<String> getCategory(String path) async {
    if (path.contains('00_INBOX')) return '00_INBOX';
    if (path.contains('10_CORE_TASKS')) return '10_CORE_TASKS';
    if (path.contains('20_STRATEGIC_PROJECT')) return '20_STRATEGIC_PROJECT';
    if (path.contains('30_KNOWLEDGE_ASSETS')) return '30_KNOWLEDGE_ASSETS';
    return 'UNCATEGORIZED';
  }

  Future<bool> pushFileToGitHub({
    required String filePath,
    required String content,
    required String commitMessage,
  }) async {
    try {
      final token = await _storage.getGitHubToken();
      final username = await _storage.getGitHubUsername();

      if (token == null || username == null) {
        print('GitSyncService: No credentials for push');
        return false;
      }

      // Get current file SHA (needed for update)
      final getUrl = 'https://api.github.com/repos/offline2k-coder/my-notion-backup/contents/$filePath';

      String? sha;
      final getResponse = await http.get(
        Uri.parse(getUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );

      if (getResponse.statusCode == 200) {
        final data = json.decode(getResponse.body);
        sha = data['sha'];
        print('GitSyncService: Found existing file with SHA: $sha');
      } else {
        print('GitSyncService: File does not exist yet, will create new');
      }

      // Encode content to base64
      final bytes = utf8.encode(content);
      final base64Content = base64.encode(bytes);

      // Create or update file
      final putUrl = 'https://api.github.com/repos/offline2k-coder/my-notion-backup/contents/$filePath';

      final body = {
        'message': commitMessage,
        'content': base64Content,
        'branch': 'main',
      };

      if (sha != null) {
        body['sha'] = sha;
      }

      final putResponse = await http.put(
        Uri.parse(putUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        body: json.encode(body),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        print('GitSyncService: Successfully pushed $filePath to GitHub');
        return true;
      } else {
        print('GitSyncService: Failed to push file. Status: ${putResponse.statusCode}');
        print('GitSyncService: Response: ${putResponse.body}');
        return false;
      }
    } catch (e) {
      print('GitSyncService: Error pushing to GitHub - $e');
      return false;
    }
  }
}
