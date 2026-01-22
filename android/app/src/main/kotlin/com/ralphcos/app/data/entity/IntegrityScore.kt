package com.ralphcos.app.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant
import java.time.LocalDate

@Entity(tableName = "integrity_scores")
data class IntegrityScore(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val weekStart: LocalDate,
    val weekEnd: LocalDate,
    val score: Double,
    val breachCount: Int,
    val repairCount: Int,
    val streakDays: Int,
    val debtDays: Int,
    val calculatedAt: Instant = Instant.now()
)
