package com.ralphcos.app.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant
import java.time.LocalDate

@Entity(tableName = "streak_state")
data class StreakState(
    @PrimaryKey
    val id: Int = 1, // Singleton row
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val lastSuccessDate: LocalDate? = null,
    val streakExtenderPasses: Int = 0, // Max 3
    val updatedAt: Instant = Instant.now()
)
