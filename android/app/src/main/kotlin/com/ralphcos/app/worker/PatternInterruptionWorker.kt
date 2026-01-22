package com.ralphcos.app.worker

import android.content.Context
import androidx.work.*
import com.ralphcos.app.service.NotificationService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalTime
import java.util.concurrent.TimeUnit

/**
 * Pattern Interruption Worker
 *
 * Sends 3× daily confrontation questions:
 * - 11:00: "What are you avoiding right now?"
 * - 13:30: "Are you Vow-aligned?"
 * - 15:00: "Evidence in Git/Notion?"
 */
class PatternInterruptionWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val notificationService = NotificationService(applicationContext)
            val questionId = inputData.getInt(KEY_QUESTION_ID, 0)

            val question = QUESTIONS.getOrNull(questionId) ?: return@withContext Result.failure()

            notificationService.sendPatternInterruption(
                NotificationService.PatternInterruptionQuestion(
                    id = questionId,
                    text = question
                )
            )

            Result.success()
        } catch (e: Exception) {
            android.util.Log.e("PatternInterrupt", "Failed to send interruption: ${e.message}", e)
            Result.retry()
        }
    }

    companion object {
        private const val KEY_QUESTION_ID = "question_id"
        private const val WORK_NAME_PREFIX = "pattern_interruption_"

        private val QUESTIONS = listOf(
            "What are you avoiding right now?",
            "Are you Vow-aligned?",
            "Evidence in Git/Notion?"
        )

        private val SCHEDULE_TIMES = listOf(
            LocalTime.of(11, 0),  // 11:00
            LocalTime.of(13, 30), // 13:30
            LocalTime.of(15, 0)   // 15:00
        )

        fun scheduleAll(context: Context) {
            SCHEDULE_TIMES.forEachIndexed { index, targetTime ->
                scheduleForTime(context, index, targetTime)
            }
        }

        private fun scheduleForTime(context: Context, questionId: Int, targetTime: LocalTime) {
            val currentTime = LocalTime.now()
            val initialDelay = if (currentTime.isBefore(targetTime)) {
                java.time.Duration.between(currentTime, targetTime).toMinutes()
            } else {
                java.time.Duration.between(currentTime, targetTime.plusHours(24)).toMinutes()
            }

            val inputData = workDataOf(KEY_QUESTION_ID to questionId)

            val request = PeriodicWorkRequestBuilder<PatternInterruptionWorker>(
                repeatInterval = 1,
                repeatIntervalTimeUnit = TimeUnit.DAYS
            )
                .setInitialDelay(initialDelay, TimeUnit.MINUTES)
                .setInputData(inputData)
                .addTag("ralph_pattern_interrupt")
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "${WORK_NAME_PREFIX}$questionId",
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancelAll(context: Context) {
            SCHEDULE_TIMES.indices.forEach { index ->
                WorkManager.getInstance(context).cancelUniqueWork("${WORK_NAME_PREFIX}$index")
            }
        }
    }
}
