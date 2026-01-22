package com.ralphcos.app.data.dao

import androidx.room.*
import com.ralphcos.app.data.entity.Challenge
import kotlinx.coroutines.flow.Flow

@Dao
interface ChallengeDao {
    @Query("SELECT * FROM challenges WHERE isActive = 1 ORDER BY startDate DESC LIMIT 1")
    suspend fun getActiveChallenge(): Challenge?

    @Query("SELECT * FROM challenges WHERE isActive = 1 ORDER BY startDate DESC LIMIT 1")
    fun observeActiveChallenge(): Flow<Challenge?>

    @Query("SELECT * FROM challenges ORDER BY startDate DESC")
    suspend fun getAllChallenges(): List<Challenge>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(challenge: Challenge): Long

    @Update
    suspend fun update(challenge: Challenge)

    @Query("UPDATE challenges SET isActive = 0 WHERE id = :challengeId")
    suspend fun deactivate(challengeId: Long)
}
