package com.ralphcos.app.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.ralphcos.app.data.dao.*
import com.ralphcos.app.data.entity.*

@Database(
    entities = [
        DailyVow::class,
        EveningClaim::class,
        Breach::class,
        IntegrityScore::class,
        StreakState::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class RalphDatabase : RoomDatabase() {
    abstract fun dailyVowDao(): DailyVowDao
    abstract fun eveningClaimDao(): EveningClaimDao
    abstract fun breachDao(): BreachDao
    abstract fun integrityScoreDao(): IntegrityScoreDao
    abstract fun streakStateDao(): StreakStateDao

    companion object {
        @Volatile
        private var INSTANCE: RalphDatabase? = null

        fun getInstance(context: Context): RalphDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    RalphDatabase::class.java,
                    "ralph_database"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
