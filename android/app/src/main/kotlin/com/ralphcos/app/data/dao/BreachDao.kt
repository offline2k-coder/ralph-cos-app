package com.ralphcos.app.data.dao

import androidx.room.*
import com.ralphcos.app.data.entity.Breach
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface BreachDao {
    @Query("SELECT * FROM breaches WHERE date >= :startDate AND date <= :endDate ORDER BY date DESC")
    suspend fun getBreachesInRange(startDate: LocalDate, endDate: LocalDate): List<Breach>

    @Query("SELECT * FROM breaches WHERE date >= :startDate AND date <= :endDate")
    fun observeBreachesInRange(startDate: LocalDate, endDate: LocalDate): Flow<List<Breach>>

    @Query("SELECT COUNT(*) FROM breaches WHERE date >= :startDate AND date <= :endDate AND repaired = 0")
    suspend fun countUnrepairedBreaches(startDate: LocalDate, endDate: LocalDate): Int

    @Query("SELECT COUNT(*) FROM breaches WHERE date >= :startDate AND date <= :endDate AND repaired = 1")
    suspend fun countRepairs(startDate: LocalDate, endDate: LocalDate): Int

    @Insert
    suspend fun insert(breach: Breach): Long

    @Update
    suspend fun update(breach: Breach)

    @Query("DELETE FROM breaches WHERE date < :beforeDate")
    suspend fun deleteOlderThan(beforeDate: LocalDate)
}
