package com.ralphcos.app.data.repository

import com.ralphcos.app.data.dao.BreachDao
import com.ralphcos.app.data.dao.IntegrityScoreDao
import com.ralphcos.app.data.dao.StreakStateDao
import com.ralphcos.app.data.entity.Breach
import com.ralphcos.app.data.entity.BreachType
import com.ralphcos.app.data.entity.IntegrityScore
import com.ralphcos.app.data.entity.StreakState
import kotlinx.coroutines.flow.Flow
import java.time.Instant
import java.time.LocalDate
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

class IntegrityRepository(
    private val breachDao: BreachDao,
    private val scoreDao: IntegrityScoreDao,
    private val streakDao: StreakStateDao
) {
    suspend fun getLatestScore(): IntegrityScore? = scoreDao.getLatestScore()
    fun observeLatestScore(): Flow<IntegrityScore?> = scoreDao.observeLatestScore()
    fun observeStreakState(): Flow<StreakState?> = streakDao.observeState()

    suspend fun getAllBreaches(): List<Breach> {
        return breachDao.getBreachesInRange(
            LocalDate.now().minusYears(1),
            LocalDate.now()
        )
    }

    suspend fun getOrCreateStreakState(): StreakState {
        return streakDao.getState() ?: StreakState().also {
            streakDao.insert(it)
        }
    }

    suspend fun recordBreach(type: BreachType, reason: String, date: LocalDate = LocalDate.now()): Long {
        val breach = Breach(
            date = date,
            type = type,
            reason = reason
        )
        val breachId = breachDao.insert(breach)

        // Reset streak or consume pass
        handleStreakBreach()

        return breachId
    }

    private suspend fun handleStreakBreach() {
        val state = getOrCreateStreakState()

        if (state.streakExtenderPasses > 0) {
            // Consume a pass
            val updated = state.copy(
                streakExtenderPasses = state.streakExtenderPasses - 1,
                updatedAt = Instant.now()
            )
            streakDao.update(updated)
        } else {
            // Reset streak
            val updated = state.copy(
                currentStreak = 0,
                updatedAt = Instant.now()
            )
            streakDao.update(updated)
        }
    }

    suspend fun incrementStreak() {
        val state = getOrCreateStreakState()
        val newStreak = state.currentStreak + 1

        // Award pass every 20 days, max 3
        val newPasses = if (newStreak % 20 == 0 && state.streakExtenderPasses < 3) {
            state.streakExtenderPasses + 1
        } else {
            state.streakExtenderPasses
        }

        val updated = state.copy(
            currentStreak = newStreak,
            longestStreak = max(state.longestStreak, newStreak),
            lastSuccessDate = LocalDate.now(),
            streakExtenderPasses = newPasses,
            updatedAt = Instant.now()
        )
        streakDao.update(updated)
    }

    suspend fun calculateIntegrityScore(startDate: LocalDate, endDate: LocalDate): IntegrityScore {
        val days = java.time.temporal.ChronoUnit.DAYS.between(startDate, endDate).toInt() + 1
        val breaches = breachDao.countUnrepairedBreaches(startDate, endDate)
        val repairs = breachDao.countRepairs(startDate, endDate)
        val state = getOrCreateStreakState()

        // Formula: max(12, 100 × (1 - min(1, Breaches^1.35 / (Days × 1.25))))
        val k = 1.25
        val breachPenalty = min(1.0, breaches.toDouble().pow(1.35) / (days * k))
        val baseScore = max(12.0, 100.0 * (1.0 - breachPenalty))

        // Repair halving: -0.5 per repair
        val repairPenalty = repairs * 0.5
        val finalScore = max(12.0, baseScore - repairPenalty)

        // Calculate debt days (days with unrepaired breaches)
        val unrepairedBreaches = breachDao.getBreachesInRange(startDate, endDate)
            .filter { !it.repaired }
        val debtDays = unrepairedBreaches.map { it.date }.distinct().size

        val score = IntegrityScore(
            weekStart = startDate,
            weekEnd = endDate,
            score = finalScore,
            breachCount = breaches,
            repairCount = repairs,
            streakDays = state.currentStreak,
            debtDays = debtDays
        )

        scoreDao.insert(score)
        return score
    }

    suspend fun repairBreach(breachId: Long) {
        val breaches = breachDao.getBreachesInRange(
            LocalDate.now().minusMonths(1),
            LocalDate.now()
        )
        val breach = breaches.find { it.id == breachId } ?: return

        val updated = breach.copy(
            repaired = true,
            repairedAt = Instant.now()
        )
        breachDao.update(updated)
    }
}
