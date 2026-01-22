package com.ralphcos.app.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant
import java.time.LocalDate

@Entity(tableName = "evening_claims")
data class EveningClaim(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val date: LocalDate,
    val vowId: Long,
    val reflectionItems: Map<String, Boolean>, // "kept_vow", "avoided", "inbox_zero", "task_zero", "guilt_zero"
    val mantraCompleted: Boolean = false,
    val gitCommitSha: String? = null,
    val completed: Boolean = false,
    val completedAt: Instant? = null,
    val createdAt: Instant = Instant.now()
)
