package com.ralphcos.app

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.google.ai.client.generativeai.GenerativeModel
import com.google.ai.client.generativeai.type.generationConfig

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.ralphcos.app/ai"
    private var generativeModel: GenerativeModel? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkSupport" -> {
                        val supported = checkGeminiNanoSupport()
                        result.success(supported)
                    }
                    "inferenceText" -> {
                        val prompt = call.argument<String>("prompt")
                        val maxTokens = call.argument<Int>("maxTokens") ?: 150

                        if (prompt == null) {
                            result.error("INVALID_ARGUMENT", "Prompt is required", null)
                            return@setMethodCallHandler
                        }

                        handleInference(prompt, maxTokens, result)
                    }
                    "initializeModel" -> {
                        initializeGeminiModel()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun checkGeminiNanoSupport(): Boolean {
        // Check if device is Pixel 9 series or has AI Core capability
        // For now, we check for Pixel 9 explicitly
        val deviceModel = Build.MODEL.uppercase()
        val manufacturer = Build.MANUFACTURER.uppercase()

        return when {
            // Pixel 9 series
            manufacturer == "GOOGLE" && deviceModel.contains("PIXEL 9") -> true
            // Pixel 8 series (limited support)
            manufacturer == "GOOGLE" && deviceModel.contains("PIXEL 8") -> true
            // Check Android version (Gemini Nano requires Android 10+)
            Build.VERSION.SDK_INT < Build.VERSION_CODES.Q -> false
            // For other devices, we can't guarantee support
            else -> false
        }
    }

    private fun initializeGeminiModel() {
        try {
            // Initialize Gemini Nano model for on-device inference
            // Note: This requires Google AI Edge SDK to be properly configured
            generativeModel = GenerativeModel(
                modelName = "gemini-nano",
                apiKey = "", // Empty for on-device, uses device's built-in model
                generationConfig = generationConfig {
                    temperature = 0.7f
                    topK = 40
                    topP = 0.95f
                    maxOutputTokens = 256
                }
            )
        } catch (e: Exception) {
            // Model initialization failed, will fallback to cloud
            android.util.Log.e("MainActivity", "Failed to initialize Gemini Nano: ${e.message}")
        }
    }

    private fun handleInference(prompt: String, maxTokens: Int, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                // Initialize model if not already done
                if (generativeModel == null) {
                    initializeGeminiModel()
                }

                if (generativeModel == null) {
                    result.error(
                        "MODEL_NOT_AVAILABLE",
                        "Gemini Nano model not available on this device",
                        null
                    )
                    return@launch
                }

                // Perform inference on background thread
                val response = withContext(Dispatchers.IO) {
                    generativeModel!!.generateContent(prompt)
                }

                val generatedText = response.text ?: ""

                // Enforce max tokens/characters limit
                val finalText = if (generatedText.length > maxTokens) {
                    generatedText.substring(0, maxTokens - 3) + "..."
                } else {
                    generatedText
                }

                result.success(finalText)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Inference error: ${e.message}")
                result.error(
                    "INFERENCE_ERROR",
                    "Failed to generate content: ${e.message}",
                    null
                )
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        generativeModel = null
    }
}
