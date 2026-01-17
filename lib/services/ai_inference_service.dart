import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_nano_channel.dart';
import 'secure_storage_service.dart';

/// Smart AI inference service that routes between on-device and cloud
///
/// Automatically uses:
/// - Gemini Nano on-device for supported devices (Pixel 9/8)
/// - Cloud Gemini API for unsupported devices or as fallback
/// - Hardcoded fallbacks if both fail
class AIInferenceService {
  static final AIInferenceService _instance = AIInferenceService._internal();
  factory AIInferenceService() => _instance;
  AIInferenceService._internal();

  final _nanoChannel = GeminiNanoChannel();
  final _storage = SecureStorageService();

  bool? _deviceSupportsNano;
  bool _modelInitialized = false;

  /// Check if current device supports Gemini Nano (cached result)
  Future<bool> get deviceSupportsNano async {
    _deviceSupportsNano ??= await _nanoChannel.isSupported();
    return _deviceSupportsNano!;
  }

  /// Initialize on-device model if supported
  Future<void> initializeOnDeviceModel() async {
    if (await deviceSupportsNano && !_modelInitialized) {
      _modelInitialized = await _nanoChannel.initializeModel();
      if (_modelInitialized) {
        print('AIInferenceService: On-device model initialized');
      }
    }
  }

  /// Generate mantra text (max 150 characters)
  ///
  /// Tries on-device first, then cloud, then hardcoded fallback
  Future<String> generateMantra(String articleContent) async {
    final prompt = _buildMantraPrompt(articleContent);

    // Try on-device inference first
    if (await deviceSupportsNano) {
      try {
        print('AIInferenceService: Attempting on-device mantra generation');
        final mantra = await _nanoChannel.inferenceText(
          prompt: prompt,
          maxTokens: 150,
        );
        print('AIInferenceService: On-device generation successful');
        return _enforceLength(mantra, 150);
      } catch (e) {
        print('AIInferenceService: On-device failed, trying cloud - $e');
      }
    }

    // Fallback to cloud
    try {
      final apiKey = await _storage.getGeminiApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        print('AIInferenceService: Using cloud API');
        final mantra = await _cloudInference(prompt, apiKey);
        return _enforceLength(mantra, 150);
      } else {
        print('AIInferenceService: No API key, using fallback');
      }
    } catch (e) {
      print('AIInferenceService: Cloud inference failed - $e');
    }

    // Last resort: hardcoded fallback
    throw Exception('No inference method available');
  }

  /// Generate task extraction (max 200 characters)
  Future<String> generateTask(String prompt) async {
    return await _inferenceWithFallback(prompt, 200);
  }

  /// Generate summary (max 500 characters)
  Future<String> generateSummary(String prompt) async {
    return await _inferenceWithFallback(prompt, 500);
  }

  /// Generic inference with on-device → cloud fallback
  Future<String> _inferenceWithFallback(String prompt, int maxLength) async {
    // Try on-device first
    if (await deviceSupportsNano) {
      try {
        final result = await _nanoChannel.inferenceText(
          prompt: prompt,
          maxTokens: maxLength,
        );
        return _enforceLength(result, maxLength);
      } catch (e) {
        print('AIInferenceService: On-device failed, trying cloud - $e');
      }
    }

    // Fallback to cloud
    final apiKey = await _storage.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key available for cloud inference');
    }

    final result = await _cloudInference(prompt, apiKey);
    return _enforceLength(result, maxLength);
  }

  /// Cloud-based inference using Gemini API
  Future<String> _cloudInference(String prompt, String apiKey) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';

    if (text.isEmpty) {
      throw Exception('Empty response from cloud inference');
    }

    return text;
  }

  /// Build mantra generation prompt
  String _buildMantraPrompt(String articleContent) {
    return '''
Based on this life philosophy article:
$articleContent

Generate ONE powerful, brutally honest daily mantra (maximum 150 characters).

Guidelines:
- Direct, commanding language (e.g., "Stop...", "Do...", "Face...")
- Focus on action TODAY, not tomorrow
- No motivational fluff, just raw truth
- Make it hit hard
- Under 150 characters

Return ONLY the mantra text, nothing else.
''';
  }

  /// Enforce maximum length with ellipsis
  String _enforceLength(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength - 3) + '...';
  }

  /// Get inference mode for UI display
  Future<String> getInferenceMode() async {
    if (await deviceSupportsNano) {
      return 'On-Device AI (Gemini Nano)';
    }

    final apiKey = await _storage.getGeminiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      return 'Cloud AI (Gemini API)';
    }

    return 'Fallback Mode';
  }

  /// Check if device has full AI capabilities
  Future<bool> hasAICapabilities() async {
    if (await deviceSupportsNano) {
      return true;
    }

    final apiKey = await _storage.getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
}
