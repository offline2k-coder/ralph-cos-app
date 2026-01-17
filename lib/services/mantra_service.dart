import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';
import 'ai_inference_service.dart';

class MantraService {
  static final MantraService _instance = MantraService._internal();
  factory MantraService() => _instance;
  MantraService._internal();

  final _database = DatabaseService();
  final _storage = SecureStorageService();
  final _aiService = AIInferenceService();

  String? _danKoeArticle;

  Future<String> _loadDanKoeArticle() async {
    if (_danKoeArticle != null) return _danKoeArticle!;

    try {
      _danKoeArticle = await rootBundle.loadString('ralph_personality/dan_koe_life_fix.md');
      return _danKoeArticle!;
    } catch (e) {
      print('MantraService: Error loading Dan Koe article - $e');
      return '';
    }
  }

  Future<String?> getTodayMantra() async {
    // Check if we already have today's mantra cached
    final cached = await _database.getTodayMantra();
    if (cached != null) {
      return cached;
    }

    // Generate a new mantra
    return await _generateMantra();
  }

  Future<String?> _generateMantra() async {
    try {
      final article = await _loadDanKoeArticle();
      if (article.isEmpty) {
        print('MantraService: Dan Koe article is empty');
        return 'No compass. No direction. Set your course.';
      }

      // Use hybrid AI service (on-device → cloud → fallback)
      final mantra = await _aiService.generateMantra(article);

      // Cache it
      await _database.saveMantra(mantra);

      return mantra;
    } catch (e) {
      print('MantraService: Error generating mantra - $e');

      // Fallback mantras if all AI methods fail
      final fallbacks = [
        'Stop planning. Start doing. Today counts or it doesn\'t.',
        'Your future self is watching. Make them proud or prove them right.',
        'Comfort is killing you slowly. Choose the hard thing.',
        'What you avoid today owns you tomorrow. Face it now.',
        'Discipline isn\'t punishment. It\'s freedom from regret.',
      ];

      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final fallback = fallbacks[dayOfYear % fallbacks.length];

      await _database.saveMantra(fallback);
      return fallback;
    }
  }

  Future<void> regenerateMantra() async {
    // Force regeneration by generating and overwriting
    await _generateMantra();
  }
}
