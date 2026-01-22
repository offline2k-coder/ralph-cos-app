package com.ralphcos.app.service

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.ralphcos.app.MainActivity
import com.ralphcos.app.R

/**
 * Notification Service for Ralph-CoS
 *
 * Handles:
 * - Morning wake-up alerts (05:00-09:00 escalation)
 * - Pattern interruptions (3× daily)
 * - Breach alerts (RED mode)
 */
class NotificationService(private val context: Context) {

    init {
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channels = listOf(
                NotificationChannel(
                    CHANNEL_MORNING_VOW,
                    "Morning Vow Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Critical morning check-in reminders"
                    enableVibration(true)
                    setShowBadge(true)
                },
                NotificationChannel(
                    CHANNEL_PATTERN_INTERRUPT,
                    "Pattern Interruptions",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Daily confrontation questions"
                    enableVibration(true)
                },
                NotificationChannel(
                    CHANNEL_BREACH_ALERT,
                    "Breach Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Integrity breach notifications"
                    enableVibration(true)
                },
                NotificationChannel(
                    CHANNEL_EVENING_RITUAL,
                    "Evening Ritual",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Evening synthesis reminders"
                }
            )

            val manager = context.getSystemService(NotificationManager::class.java)
            channels.forEach { manager.createNotificationChannel(it) }
        }
    }

    fun sendMorningVowAlert(escalationLevel: Int = 1) {
        if (!hasNotificationPermission()) return

        val messages = listOf(
            "Aufstehen! Keine Ausreden!",
            "MORNING VOW – 09:00 Deadline approaching!",
            "LAST WARNING: Check in NOW or BREACH!",
            "STREAK BREAKING IN 5 MINUTES!"
        )

        val message = messages.getOrNull(escalationLevel - 1) ?: messages.last()

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("navigate_to", "morning_vow")
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_MORNING_VOW)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Ralph: Morning Vow")
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context)
            .notify(NOTIFICATION_ID_MORNING_VOW, notification)
    }

    fun sendPatternInterruption(question: PatternInterruptionQuestion) {
        if (!hasNotificationPermission()) return

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("navigate_to", "pattern_interruption")
            putExtra("question", question.text)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            question.id,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_PATTERN_INTERRUPT)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Ralph: Pattern Interruption")
            .setContentText(question.text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(question.text))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context)
            .notify(NOTIFICATION_ID_PATTERN_BASE + question.id, notification)
    }

    fun sendBreachAlert(message: String) {
        if (!hasNotificationPermission()) return

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_BREACH_ALERT)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Ralph: INTEGRITY BREACH")
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ERROR)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .build()

        NotificationManagerCompat.from(context)
            .notify(NOTIFICATION_ID_BREACH, notification)
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    companion object {
        private const val CHANNEL_MORNING_VOW = "morning_vow"
        private const val CHANNEL_PATTERN_INTERRUPT = "pattern_interrupt"
        private const val CHANNEL_BREACH_ALERT = "breach_alert"
        private const val CHANNEL_EVENING_RITUAL = "evening_ritual"

        private const val NOTIFICATION_ID_MORNING_VOW = 1001
        private const val NOTIFICATION_ID_PATTERN_BASE = 2000
        private const val NOTIFICATION_ID_BREACH = 3001
    }

    data class PatternInterruptionQuestion(
        val id: Int,
        val text: String
    )
}
