package com.ralphcos.app.worker

import android.content.Context
import androidx.work.*
import com.ralphcos.app.data.RalphDatabase
import com.ralphcos.app.data.entity.BreachType
import com.ralphcos.app.data.repository.IntegrityRepository
import com.ralphcos.app.data.repository.VowRepository
import com.ralphcos.app.service.GitHubService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.LocalTime
import java.util.concurrent.TimeUnit

/**
 * Core Ralph Loop: Delayed Audit Worker
 *
 * Runs every morning at 04:00-05:00 to audit yesterday's claim vs GitHub state.
 *
 * Match → Streak +1, Score update
 * Mismatch → Streak Reset, BREACH, RED-Mode
 */
class DelayedAuditWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val db = RalphDatabase.getInstance(applicationContext)
            val vowRepo = VowRepository(db.dailyVowDao(), db.eveningClaimDao())
            val integrityRepo = IntegrityRepository(
                db.breachDao(),
                db.integrityScoreDao(),
                db.streakStateDao()
            )
            val githubService = GitHubService(applicationContext)

            // Audit yesterday's claim
            val yesterday = LocalDate.now().minusDays(1)
            val claim = db.eveningClaimDao().getClaimForDate(yesterday)

            if (claim == null) {
                // No claim submitted yesterday → BREACH
                integrityRepo.recordBreach(
                    type = BreachType.MISSED_EVENING_CLAIM,
                    reason = "No evening claim submitted for ${yesterday}",
                    date = yesterday
                )
                android.util.Log.w("DelayedAudit", "BREACH: No claim for $yesterday")
                return@withContext Result.success()
            }

            // Check GitHub state (last commit around 00:00)
            val isGitStateValid = githubService.verifyCommitForDate(yesterday)

            if (!isGitStateValid) {
                // Claim vs GitHub mismatch → BREACH
                integrityRepo.recordBreach(
                    type = BreachType.AUDIT_MISMATCH,
                    reason = "Claim submitted but no matching Git commit for ${yesterday}",
                    date = yesterday
                )
                android.util.Log.w("DelayedAudit", "BREACH: Audit mismatch for $yesterday")
                return@withContext Result.success()
            }

            // Success: Increment streak
            integrityRepo.incrementStreak()
            android.util.Log.i("DelayedAudit", "SUCCESS: Audit passed for $yesterday, streak incremented")

            Result.success()
        } catch (e: Exception) {
            android.util.Log.e("DelayedAudit", "Audit failed: ${e.message}", e)
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "delayed_audit_work"

        fun schedule(context: Context) {
            val currentTime = LocalTime.now()
            val targetTime = LocalTime.of(4, 30) // 04:30 CET

            val initialDelay = if (currentTime.isBefore(targetTime)) {
                java.time.Duration.between(currentTime, targetTime).toMinutes()
            } else {
                // Schedule for tomorrow
                java.time.Duration.between(currentTime, targetTime.plusHours(24)).toMinutes()
            }

            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(false) // Run even on low battery
                .build()

            val auditRequest = PeriodicWorkRequestBuilder<DelayedAuditWorker>(
                repeatInterval = 1,
                repeatIntervalTimeUnit = TimeUnit.DAYS
            )
                .setInitialDelay(initialDelay, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .addTag("ralph_audit")
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                auditRequest
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
