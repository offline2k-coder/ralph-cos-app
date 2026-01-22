package com.ralphcos.app.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant
import java.time.LocalDate

/**
 * Entity for 30-Day Challenge
 * Stores all 30 challenges with start date and tracking
 */
@Entity(tableName = "challenges")
data class Challenge(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val startDate: LocalDate,
    val challenges: List<String>, // 30 challenges in order
    val isActive: Boolean = true,
    val completedDays: Int = 0,
    val createdAt: Instant = Instant.now()
)
