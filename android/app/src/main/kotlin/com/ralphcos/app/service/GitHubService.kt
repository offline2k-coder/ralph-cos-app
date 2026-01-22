package com.ralphcos.app.service

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * GitHub Integration Service
 *
 * Handles:
 * - PAT secure storage
 * - Auto-commit audit files (logs/audit_YYYY-MM-DD.md + claim.json)
 * - Verification of commits for audit
 */
class GitHubService(private val context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val securePrefs = EncryptedSharedPreferences.create(
        context,
        "github_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun savePAT(pat: String) {
        securePrefs.edit().putString(KEY_PAT, pat).apply()
    }

    fun saveUsername(username: String) {
        securePrefs.edit().putString(KEY_USERNAME, username).apply()
    }

    fun getPAT(): String? = securePrefs.getString(KEY_PAT, null)
    fun getUsername(): String? = securePrefs.getString(KEY_USERNAME, null)

    suspend fun verifyCommitForDate(date: LocalDate): Boolean = withContext(Dispatchers.IO) {
        val pat = getPAT() ?: return@withContext false
        val username = getUsername() ?: return@withContext false

        // TODO: Implement actual GitHub API call
        // For now, check if local audit file exists (offline fallback)
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val dateStr = date.format(formatter)
        val auditFile = File(context.filesDir, "logs/audit_$dateStr.md")

        auditFile.exists()
    }

    suspend fun commitAuditFiles(date: LocalDate, claimData: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val pat = getPAT() ?: return@withContext false
            val username = getUsername() ?: return@withContext false

            // Create audit file
            val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
            val dateStr = date.format(formatter)

            val logsDir = File(context.filesDir, "logs")
            logsDir.mkdirs()

            val auditFile = File(logsDir, "audit_$dateStr.md")
            auditFile.writeText("""
                # Daily Audit: $dateStr

                ## Claim Data
                $claimData

                ## Timestamp
                ${java.time.Instant.now()}
            """.trimIndent())

            // TODO: Implement actual git commit & push
            // For MVP: Just create local files, sync when online

            android.util.Log.i("GitHubService", "Audit file created: ${auditFile.absolutePath}")
            true
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Failed to commit audit files: ${e.message}", e)
            false
        }
    }

    companion object {
        private const val KEY_PAT = "github_pat"
        private const val KEY_USERNAME = "github_username"
    }
}
