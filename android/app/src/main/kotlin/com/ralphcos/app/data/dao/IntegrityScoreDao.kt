package com.ralphcos.app.data.dao

import androidx.room.*
import com.ralphcos.app.data.entity.IntegrityScore
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface IntegrityScoreDao {
    @Query("SELECT * FROM integrity_scores WHERE weekStart = :weekStart LIMIT 1")
    suspend fun getScoreForWeek(weekStart: LocalDate): IntegrityScore?

    @Query("SELECT * FROM integrity_scores ORDER BY weekStart DESC LIMIT 1")
    fun observeLatestScore(): Flow<IntegrityScore?>

    @Query("SELECT * FROM integrity_scores ORDER BY weekStart DESC LIMIT 12")
    fun observeRecentScores(): Flow<List<IntegrityScore>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(score: IntegrityScore): Long

    @Update
    suspend fun update(score: IntegrityScore)

    @Query("DELETE FROM integrity_scores WHERE weekStart < :beforeDate")
    suspend fun deleteOlderThan(beforeDate: LocalDate)
}
