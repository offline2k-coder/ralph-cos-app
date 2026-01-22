package com.ralphcos.app.data.dao

import androidx.room.*
import com.ralphcos.app.data.entity.EveningClaim
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface EveningClaimDao {
    @Query("SELECT * FROM evening_claims WHERE date = :date LIMIT 1")
    suspend fun getClaimForDate(date: LocalDate): EveningClaim?

    @Query("SELECT * FROM evening_claims WHERE date = :date LIMIT 1")
    fun observeClaimForDate(date: LocalDate): Flow<EveningClaim?>

    @Query("SELECT * FROM evening_claims ORDER BY date DESC LIMIT 30")
    fun observeRecentClaims(): Flow<List<EveningClaim>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(claim: EveningClaim): Long

    @Update
    suspend fun update(claim: EveningClaim)

    @Query("DELETE FROM evening_claims WHERE date < :beforeDate")
    suspend fun deleteOlderThan(beforeDate: LocalDate)
}
