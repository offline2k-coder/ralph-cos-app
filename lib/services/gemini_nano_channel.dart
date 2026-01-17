import 'package:flutter/services.dart';

/// Platform channel for communicating with Gemini Nano on-device AI
class GeminiNanoChannel {
  static const platform = MethodChannel('com.ralphcos.app/ai');

  /// Check if the current device supports Gemini Nano on-device inference
  ///
  /// Returns true for Pixel 9 series and Pixel 8 series devices
  /// Returns false for other devices
  Future<bool> isSupported() async {
    try {
      final result = await platform.invokeMethod<bool>('checkSupport');
      return result ?? false;
    } on PlatformException catch (e) {
      print('GeminiNanoChannel: Error checking support - ${e.message}');
      return false;
    } catch (e) {
      print('GeminiNanoChannel: Unexpected error - $e');
      return false;
    }
  }

  /// Initialize the Gemini Nano model on the device
  ///
  /// Call this once during app startup for supported devices
  Future<bool> initializeModel() async {
    try {
      final result = await platform.invokeMethod<bool>('initializeModel');
      print('GeminiNanoChannel: Model initialized successfully');
      return result ?? false;
    } on PlatformException catch (e) {
      print('GeminiNanoChannel: Error initializing model - ${e.message}');
      return false;
    } catch (e) {
      print('GeminiNanoChannel: Unexpected error - $e');
      return false;
    }
  }

  /// Generate text using on-device Gemini Nano inference
  ///
  /// [prompt] - The input prompt for text generation
  /// [maxTokens] - Maximum number of characters/tokens in the response (default: 150)
  ///
  /// Returns generated text or throws an exception if inference fails
  Future<String> inferenceText({
    required String prompt,
    int maxTokens = 150,
  }) async {
    try {
      final result = await platform.invokeMethod<String>('inferenceText', {
        'prompt': prompt,
        'maxTokens': maxTokens,
      });

      if (result == null || result.isEmpty) {
        throw Exception('Empty response from on-device inference');
      }

      return result;
    } on PlatformException catch (e) {
      if (e.code == 'MODEL_NOT_AVAILABLE') {
        throw ModelNotAvailableException(
          'Gemini Nano model not available on this device',
        );
      } else if (e.code == 'INFERENCE_ERROR') {
        throw InferenceException(
          'On-device inference failed: ${e.message}',
        );
      } else {
        throw Exception('Platform error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Inference error: $e');
    }
  }
}

/// Exception thrown when Gemini Nano model is not available on the device
class ModelNotAvailableException implements Exception {
  final String message;
  ModelNotAvailableException(this.message);

  @override
  String toString() => 'ModelNotAvailableException: $message';
}

/// Exception thrown when on-device inference fails
class InferenceException implements Exception {
  final String message;
  InferenceException(this.message);

  @override
  String toString() => 'InferenceException: $message';
}
