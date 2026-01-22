package com.ralphcos.app.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant
import java.time.LocalDate

enum class BreachType {
    MISSED_MORNING_VOW,      // Missed 05:00-09:00 window
    MISSED_EVENING_CLAIM,    // Didn't complete evening ritual
    AUDIT_MISMATCH,          // Claim vs GitHub state mismatch
    IGNORED_INTERRUPTION     // Ignored pattern interruptions
}

@Entity(tableName = "breaches")
data class Breach(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val date: LocalDate,
    val type: BreachType,
    val reason: String,
    val repaired: Boolean = false,
    val repairedAt: Instant? = null,
    val createdAt: Instant = Instant.now()
)
