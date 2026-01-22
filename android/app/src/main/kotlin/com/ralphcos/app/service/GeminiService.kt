package com.ralphcos.app.service

import android.content.Context
import android.util.Log
import com.google.ai.client.generativeai.GenerativeModel
import com.google.ai.client.generativeai.type.BlockThreshold
import com.google.ai.client.generativeai.type.HarmCategory
import com.google.ai.client.generativeai.type.SafetySetting
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Gemini AI Service
 *
 * Provides on-device AI capabilities for:
 * - Daily mantra generation
 * - Reflection prompt generation
 * - Challenge feedback
 * - Anti-vision/vision analysis
 */
class GeminiService(private val context: Context) {

    // Use Gemini Flash for fast on-device generation
    private val generativeModel = GenerativeModel(
        modelName = "gemini-1.5-flash",
        apiKey = getApiKey(),
        safetySettings = listOf(
            SafetySetting(HarmCategory.HARASSMENT, BlockThreshold.MEDIUM_AND_ABOVE),
            SafetySetting(HarmCategory.HATE_SPEECH, BlockThreshold.MEDIUM_AND_ABOVE),
            SafetySetting(HarmCategory.SEXUALLY_EXPLICIT, BlockThreshold.MEDIUM_AND_ABOVE),
            SafetySetting(HarmCategory.DANGEROUS_CONTENT, BlockThreshold.MEDIUM_AND_ABOVE),
        )
    )

    private fun getApiKey(): String {
        // In production, store API key securely
        // For now, return empty string - will need to be configured
        return ""
    }

    /**
     * Generate a daily mantra based on integrity state
     */
    suspend fun generateDailyMantra(
        streakDays: Int,
        recentBreaches: Int,
        context: String = ""
    ): String = withContext(Dispatchers.IO) {
        try {
            val prompt = buildString {
                append("Generate a short, powerful daily mantra (1 sentence, max 15 words) ")
                append("for someone maintaining personal integrity and discipline.\n\n")
                append("Current context:\n")
                append("- Streak: $streakDays days\n")
                append("- Recent breaches: $recentBreaches\n")
                if (context.isNotEmpty()) {
                    append("- Additional context: $context\n")
                }
                append("\nStyle: Direct, brutal, drill-sergeant tone. ")
                append("No fluff. Maximum impact. German or English.")
            }

            val response = generativeModel.generateContent(prompt)
            response.text?.trim() ?: getDefaultMantra()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate mantra: ${e.message}", e)
            getDefaultMantra()
        }
    }

    /**
     * Generate reflection prompt for evening ritual
     */
    suspend fun generateReflectionPrompt(date: String, vowCompleted: Boolean): String =
        withContext(Dispatchers.IO) {
            try {
                val prompt = buildString {
                    append("Generate ONE sharp reflection question (max 20 words) ")
                    append("for an evening integrity check-in.\n\n")
                    append("Context:\n")
                    append("- Date: $date\n")
                    append("- Morning vow completed: $vowCompleted\n\n")
                    append("Question should probe:\n")
                    append("- What was avoided today\n")
                    append("- Where discipline slipped\n")
                    append("- What excuses were made\n\n")
                    append("Style: Ruthlessly direct. No mercy. German or English.")
                }

                val response = generativeModel.generateContent(prompt)
                response.text?.trim() ?: "Was hast du heute vermieden?"
            } catch (e: Exception) {
                Log.e(TAG, "Failed to generate reflection: ${e.message}", e)
                "Was hast du heute vermieden?"
            }
        }

    /**
     * Generate feedback for 30-day challenge
     */
    suspend fun generateChallengeFeedback(
        challengeDay: Int,
        totalBreaches: Int,
        currentScore: Double
    ): String = withContext(Dispatchers.IO) {
        try {
            val prompt = buildString {
                append("Generate brutal but constructive feedback (2-3 sentences, max 50 words) ")
                append("for someone on a 30-day integrity challenge.\n\n")
                append("Stats:\n")
                append("- Challenge day: $challengeDay/30\n")
                append("- Total breaches: $totalBreaches\n")
                append("- Current integrity score: $currentScore/100\n\n")
                append("Tone: Ralph - your brutal Chief of Staff. ")
                append("Acknowledge progress, but show no mercy for failures. ")
                append("End with one concrete action. German or English.")
            }

            val response = generativeModel.generateContent(prompt)
            response.text?.trim() ?: getDefaultFeedback(challengeDay)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate feedback: ${e.message}", e)
            getDefaultFeedback(challengeDay)
        }
    }

    /**
     * Analyze anti-vision vs vision statement
     */
    suspend fun analyzeVision(
        antiVision: String,
        vision: String
    ): String = withContext(Dispatchers.IO) {
        try {
            val prompt = buildString {
                append("Analyze these life vision statements (max 100 words):\n\n")
                append("ANTI-VISION (what to avoid):\n$antiVision\n\n")
                append("VISION (what to become):\n$vision\n\n")
                append("Provide:\n")
                append("1. Gap analysis: Where are the biggest risks?\n")
                append("2. One concrete daily action to move toward vision\n\n")
                append("Style: Direct, actionable, no platitudes. German or English.")
            }

            val response = generativeModel.generateContent(prompt)
            response.text?.trim() ?: "Definiere klare tägliche Aktionen."
        } catch (e: Exception) {
            Log.e(TAG, "Failed to analyze vision: ${e.message}", e)
            "Definiere klare tägliche Aktionen."
        }
    }

    /**
     * Generate pattern interruption message
     */
    suspend fun generateInterruptionMessage(
        timeOfDay: String,
        streakDays: Int
    ): String = withContext(Dispatchers.IO) {
        try {
            val prompt = buildString {
                append("Generate a short pattern interruption message (1 sentence, max 12 words) ")
                append("to break autopilot mode.\n\n")
                append("Context:\n")
                append("- Time: $timeOfDay\n")
                append("- Current streak: $streakDays days\n\n")
                append("Purpose: Force conscious awareness. Ask a hard question. ")
                append("Style: Drill sergeant. German or English.")
            }

            val response = generativeModel.generateContent(prompt)
            response.text?.trim() ?: getDefaultInterruption()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate interruption: ${e.message}", e)
            getDefaultInterruption()
        }
    }

    // Fallback defaults
    private fun getDefaultMantra(): String = "Integrität ist die einzige Währung."

    private fun getDefaultFeedback(day: Int): String = when {
        day < 10 -> "Tag $day. Früh im Spiel. Keine Ausreden."
        day < 20 -> "Tag $day. Halbzeit. Jetzt wird's ernst."
        else -> "Tag $day. Endspurt. Keine Gnade mehr."
    }

    private fun getDefaultInterruption(): String = "Was vermeidest du gerade?"

    companion object {
        private const val TAG = "GeminiService"
    }
}
