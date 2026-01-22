package com.ralphcos.app.data.repository

import com.ralphcos.app.data.dao.DailyVowDao
import com.ralphcos.app.data.dao.EveningClaimDao
import com.ralphcos.app.data.entity.DailyVow
import com.ralphcos.app.data.entity.EveningClaim
import kotlinx.coroutines.flow.Flow
import java.time.Instant
import java.time.LocalDate

class VowRepository(
    private val vowDao: DailyVowDao,
    private val claimDao: EveningClaimDao
) {
    fun observeTodayVow(): Flow<DailyVow?> {
        return vowDao.observeVowForDate(LocalDate.now())
    }

    fun observeTodayClaim(): Flow<EveningClaim?> {
        return claimDao.observeClaimForDate(LocalDate.now())
    }

    suspend fun createTodayVow(levers: List<String>): Long {
        val today = LocalDate.now()
        val vow = DailyVow(
            date = today,
            levers = levers
        )
        return vowDao.insert(vow)
    }

    suspend fun completeMorningVow(): Boolean {
        val today = LocalDate.now()
        val vow = vowDao.getVowForDate(today) ?: return false

        val updated = vow.copy(
            completed = true,
            completedAt = Instant.now()
        )
        vowDao.update(updated)
        return true
    }

    suspend fun createEveningClaim(
        vowId: Long,
        reflectionItems: Map<String, Boolean>,
        mantraCompleted: Boolean
    ): Long {
        val today = LocalDate.now()
        val claim = EveningClaim(
            date = today,
            vowId = vowId,
            reflectionItems = reflectionItems,
            mantraCompleted = mantraCompleted
        )
        return claimDao.insert(claim)
    }

    suspend fun completeEveningClaim(claimId: Long, gitCommitSha: String?): Boolean {
        val claim = claimDao.getClaimForDate(LocalDate.now()) ?: return false

        val updated = claim.copy(
            completed = true,
            completedAt = Instant.now(),
            gitCommitSha = gitCommitSha
        )
        claimDao.update(updated)
        return true
    }
}
