package com.ralphcos.app.data.dao

import androidx.room.*
import com.ralphcos.app.data.entity.DailyVow
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface DailyVowDao {
    @Query("SELECT * FROM daily_vows WHERE date = :date LIMIT 1")
    suspend fun getVowForDate(date: LocalDate): DailyVow?

    @Query("SELECT * FROM daily_vows WHERE date = :date LIMIT 1")
    fun observeVowForDate(date: LocalDate): Flow<DailyVow?>

    @Query("SELECT * FROM daily_vows ORDER BY date DESC LIMIT 30")
    fun observeRecentVows(): Flow<List<DailyVow>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(vow: DailyVow): Long

    @Update
    suspend fun update(vow: DailyVow)

    @Query("DELETE FROM daily_vows WHERE date < :beforeDate")
    suspend fun deleteOlderThan(beforeDate: LocalDate)
}
