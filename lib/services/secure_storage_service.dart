import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  // GitHub credentials
  Future<void> saveGitHubToken(String token) async {
    await _storage.write(key: 'github_token', value: token);
  }

  Future<String?> getGitHubToken() async {
    return await _storage.read(key: 'github_token');
  }

  Future<void> saveGitHubUsername(String username) async {
    await _storage.write(key: 'github_username', value: username);
  }

  Future<String?> getGitHubUsername() async {
    return await _storage.read(key: 'github_username');
  }

  Future<void> saveRepoUrl(String url) async {
    await _storage.write(key: 'repo_url', value: url);
  }

  Future<String?> getRepoUrl() async {
    return await _storage.read(key: 'repo_url');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasGitHubCredentials() async {
    final token = await getGitHubToken();
    final username = await getGitHubUsername();
    return token != null && username != null;
  }

  // Gemini API credentials
  Future<void> saveGeminiApiKey(String apiKey) async {
    await _storage.write(key: 'gemini_api_key', value: apiKey);
  }

  Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: 'gemini_api_key');
  }
}
