package com.ralphcos.app.data.dao

import androidx.room.*
import com.ralphcos.app.data.entity.StreakState
import kotlinx.coroutines.flow.Flow

@Dao
interface StreakStateDao {
    @Query("SELECT * FROM streak_state WHERE id = 1 LIMIT 1")
    suspend fun getState(): StreakState?

    @Query("SELECT * FROM streak_state WHERE id = 1 LIMIT 1")
    fun observeState(): Flow<StreakState?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(state: StreakState)

    @Update
    suspend fun update(state: StreakState)
}
