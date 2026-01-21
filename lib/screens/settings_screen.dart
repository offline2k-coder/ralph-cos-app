import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/secure_storage_service.dart';
import '../services/git_sync_service.dart';
import '../services/database_service.dart';
import '../services/content_parser_service.dart';
import '../services/challenge_service.dart';
import '../services/ai_inference_service.dart';
import '../data/default_challenge_template.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();
  final _challengeTemplateController = TextEditingController();
  final _storage = SecureStorageService();
  final _gitSync = GitSyncService();
  final _db = DatabaseService();
  final _parser = ContentParserService();
  final _challengeService = ChallengeService();
  final _aiService = AIInferenceService();

  bool _isLoading = false;
  bool _isSyncing = false;
  String _statusMessage = '';
  bool _hasActiveChallenge = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final username = await _storage.getGitHubUsername();
    final token = await _storage.getGitHubToken();
    final geminiKey = await _storage.getGeminiApiKey();
    final challengeConfig = await _db.getChallengeConfig();

    if (username != null) _usernameController.text = username;
    if (token != null) _tokenController.text = token;
    if (geminiKey != null) _geminiApiKeyController.text = geminiKey;

    if (challengeConfig != null) {
      _challengeTemplateController.text = challengeConfig['template'] ?? '';
      setState(() {
        _hasActiveChallenge = challengeConfig['isActive'] == 1;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_usernameController.text.isEmpty || _tokenController.text.isEmpty) {
      _showMessage('Username and Token required', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    await _storage.saveGitHubUsername(_usernameController.text);
    await _storage.saveGitHubToken(_tokenController.text);

    setState(() => _isLoading = false);
    _showMessage('Credentials saved!', isError: false);
  }

  Future<void> _saveGeminiKey() async {
    if (_geminiApiKeyController.text.isEmpty) {
      _showMessage('Gemini API key required', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    await _storage.saveGeminiApiKey(_geminiApiKeyController.text);

    setState(() => _isLoading = false);
    _showMessage('Gemini API key saved!', isError: false);
  }

  Future<void> _loadDefaultTemplate() async {
    setState(() {
      _challengeTemplateController.text = defaultChallengeTemplate;
    });
    _showMessage('Default template loaded', isError: false);
  }

  Future<void> _clearTemplate() async {
    setState(() {
      _challengeTemplateController.text = '';
    });
    _showMessage('Template cleared', isError: false);
  }

  Future<void> _saveTemplate() async {
    if (_challengeTemplateController.text.isEmpty) {
      _showMessage('Template cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Save template to database (without starting challenge)
    final config = await _db.getChallengeConfig();
    final db = await _db.database;
    if (config != null) {
      await db.update(
        'challenge_config',
        {'template': _challengeTemplateController.text},
        where: 'id = ?',
        whereArgs: [config['id']],
      );
    } else {
      await db.insert('challenge_config', {
        'template': _challengeTemplateController.text,
        'isActive': 0,
        'currentDay': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    setState(() => _isLoading = false);
    _showMessage('Template saved!', isError: false);
  }

  Future<void> _startChallenge() async {
    final template = _challengeTemplateController.text.isEmpty
        ? defaultChallengeTemplate
        : _challengeTemplateController.text;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start 30-Day Challenge?'),
        content: Text(
          _challengeTemplateController.text.isEmpty
              ? 'This starts the built-in 30-Day CIO Ascent Challenge.\n\nYou\'ll complete one 500-character task per day.\n\nAre you ready to commit?'
              : 'This starts your custom 30-Day Challenge.\n\nYou\'ll complete one task per day.\n\nAre you ready to commit?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
            child: const Text('START CHALLENGE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      // Use custom template if provided, otherwise default
      await _challengeService.startChallenge(template);

      setState(() => _isLoading = false);
      await _loadCredentials(); // Reload to update button state

      _showMessage('Challenge started! Day 1 begins now.', isError: false);
    }
  }

  Future<void> _viewTemplateFormat() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('30-Day Challenge Template Format'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Each day should follow this format:',
                  style: TextStyle(
                    color: Colors.deepOrange.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: SelectableText(
                    defaultChallengeTemplate,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Format Rules:',
                  style: TextStyle(
                    color: Colors.deepOrange.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Start each day with "Day X:"\n'
                  '• Each day description: ~500 characters\n'
                  '• Day 25 must include next challenge planning\n'
                  '• Day 30 is the final milestone',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: defaultChallengeTemplate));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Template copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('COPY TEMPLATE'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow() async {
    if (!await _storage.hasGitHubCredentials()) {
      _showMessage('Please save credentials first', isError: true);
      return;
    }

    setState(() {
      _isSyncing = true;
      _statusMessage = 'Syncing repository...';
    });

    // Clone/Pull repo
    final success = await _gitSync.sync();

    if (!success) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'Sync failed. Check credentials.';
      });
      _showMessage('Sync failed', isError: true);
      return;
    }

    setState(() => _statusMessage = 'Parsing content...');

    // Parse content
    final tasks = await _parser.parseAllContent();

    setState(() => _statusMessage = 'Updating database...');

    // Clear old tasks and insert new ones
    await _db.clearAllTasks();
    await _db.insertTasks(tasks);

    setState(() {
      _isSyncing = false;
      _statusMessage = 'Sync complete! ${tasks.length} tasks loaded.';
    });

    _showMessage('Sync successful! ${tasks.length} tasks loaded', isError: false);
  }

  Future<void> _resetStreak() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Streak?'),
        content: const Text('This will reset your streak to 0. Cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final streak = await _db.getStreakData();
      if (streak != null) {
        await _db.updateStreakData(streak.copyWith(
          currentStreak: 0,
          passesAvailable: 0,
        ));
        _showMessage('Streak reset', isError: false);
      }
    }
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'SETTINGS',
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
            // GitHub Credentials Section
            Text(
              'GITHUB CREDENTIALS',
              style: TextStyle(
                color: Colors.deepOrange.shade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'GitHub Username',
                hintText: 'offline2k-coder',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Personal Access Token (PAT)',
                hintText: 'ghp_...',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                prefixIcon: const Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveCredentials,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('SAVE CREDENTIALS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Gemini AI Section
            Text(
              'GEMINI AI (FOR DAILY MANTRAS)',
              style: TextStyle(
                color: Colors.deepOrange.shade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // AI Capability Indicator
            FutureBuilder<String>(
              future: _aiService.getInferenceMode(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final mode = snapshot.data!;
                final isOnDevice = mode.contains('On-Device');
                final isCloud = mode.contains('Cloud');

                return Card(
                  color: isOnDevice
                      ? Colors.green.shade900
                      : (isCloud ? Colors.orange.shade900 : Colors.grey.shade800),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          isOnDevice
                              ? Icons.offline_bolt
                              : (isCloud ? Icons.cloud : Icons.warning),
                          color: isOnDevice
                              ? Colors.green.shade300
                              : (isCloud ? Colors.orange.shade300 : Colors.grey.shade400),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOnDevice
                                    ? 'Privacy-first, works offline, no API costs'
                                    : (isCloud
                                        ? 'Requires internet and API key'
                                        : 'Configure API key or use supported device'),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _geminiApiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Gemini API Key (Optional for Pixel 9)',
                hintText: 'AIza...',
                helperText: 'Optional: Get API key from ai.google.dev for cloud fallback',
                helperMaxLines: 2,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                prefixIcon: const Icon(Icons.psychology),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveGeminiKey,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('SAVE API KEY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 30-Day Challenge Section
            Text(
              '30-DAY CIO ASCENT CHALLENGE',
              style: TextStyle(
                color: Colors.deepOrange.shade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create or Edit Challenge Template',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _challengeTemplateController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: 'Paste or edit your 30-day challenge template here...\n\nFormat: Day 1: Task description (~500 chars)\nDay 2: ...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadDefaultTemplate,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('LOAD DEFAULT', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade300,
                              side: BorderSide(color: Colors.blue.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearTemplate,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('CLEAR', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade300,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveTemplate,
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('SAVE', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _hasActiveChallenge) ? null : _startChallenge,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_hasActiveChallenge ? 'CHALLENGE ACTIVE' : 'START CHALLENGE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasActiveChallenge ? Colors.green.shade700 : Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _viewTemplateFormat,
                icon: const Icon(Icons.description),
                label: const Text('VIEW TEMPLATE FORMAT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepOrange.shade300,
                  side: BorderSide(color: Colors.deepOrange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Sync Section
            Text(
              'NOTION BACKUP SYNC',
              style: TextStyle(
                color: Colors.deepOrange.shade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isSyncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_isSyncing) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: const Icon(Icons.sync),
                label: const Text('SYNC NOW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Danger Zone
            Text(
              'DANGER ZONE',
              style: TextStyle(
                color: Colors.red.shade300,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetStreak,
                icon: const Icon(Icons.delete_forever),
                label: const Text('RESET STREAK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    _geminiApiKeyController.dispose();
    _challengeTemplateController.dispose();
    super.dispose();
  }
}
