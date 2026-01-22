package com.ralphcos.app.service

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Base64

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

    private val httpClient = OkHttpClient.Builder()
        .build()

    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

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

        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val dateStr = date.format(formatter)

        // Check GitHub first
        val repo = "my-notion-backup"
        val path = "ralph-cos-audits/$dateStr.md"

        try {
            val url = "https://api.github.com/repos/$username/$repo/contents/$path"
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .get()
                .build()

            val response = httpClient.newCall(request).execute()
            val exists = response.isSuccessful
            response.close()

            if (exists) {
                return@withContext true
            }
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Error verifying commit: ${e.message}", e)
        }

        // Fallback to local file check
        val auditFile = File(context.filesDir, "logs/audit_$dateStr.md")
        auditFile.exists()
    }

    suspend fun commitAuditFiles(date: LocalDate, claimData: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val pat = getPAT() ?: return@withContext false
            val username = getUsername() ?: return@withContext false

            // Create new audit entry
            val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
            val dateStr = date.format(formatter)

            val newEntry = """
                # Daily Audit: $dateStr

                ## Claim Data
                $claimData

                ## Timestamp
                ${java.time.Instant.now()}

                ---

            """.trimIndent()

            // Save locally first (fallback)
            val logsDir = File(context.filesDir, "logs")
            logsDir.mkdirs()
            val auditFile = File(logsDir, "audit_$dateStr.md")
            auditFile.writeText(newEntry)

            // Append to single audit log file on GitHub
            val repo = "my-notion-backup"
            val filePath = "ralph-cos-audits/audit-log.md"
            val commitMessage = "Daily audit: $dateStr"

            val success = appendToGitHubFile(
                username = username,
                repo = repo,
                path = filePath,
                newContent = newEntry,
                message = commitMessage,
                pat = pat
            )

            android.util.Log.i("GitHubService", "Audit entry ${if (success) "committed" else "saved locally"}: $dateStr")
            success
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Failed to commit audit files: ${e.message}", e)
            false
        }
    }

    private suspend fun appendToGitHubFile(
        username: String,
        repo: String,
        path: String,
        newContent: String,
        message: String,
        pat: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            // Check if repository exists
            if (!checkRepoExists(username, repo, pat)) {
                android.util.Log.e("GitHubService", "Repository $repo doesn't exist. Please create it manually on GitHub.")
                return@withContext false
            }

            // Get existing file content and SHA
            val (existingContent, existingSha) = getFileContent(username, repo, path, pat)

            // Append new content to existing
            val fullContent = if (existingContent.isNotEmpty()) {
                "$existingContent\n\n$newContent"
            } else {
                "# Ralph-CoS Audit Log\n\nAll daily audits in chronological order.\n\n---\n\n$newContent"
            }

            // Encode content to base64
            val base64Content = Base64.getEncoder().encodeToString(fullContent.toByteArray())

            // Create JSON payload
            val jsonPayload = JSONObject().apply {
                put("message", message)
                put("content", base64Content)
                existingSha?.let { put("sha", it) }
            }

            // Make API request
            val url = "https://api.github.com/repos/$username/$repo/contents/$path"
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .header("X-GitHub-Api-Version", "2022-11-28")
                .put(jsonPayload.toString().toRequestBody(jsonMediaType))
                .build()

            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful

            if (!success) {
                android.util.Log.e("GitHubService", "GitHub API error: ${response.code} - ${response.body?.string()}")
            }

            response.close()
            success
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Failed to append to GitHub file: ${e.message}", e)
            false
        }
    }

    private suspend fun commitFileToGitHub(
        username: String,
        repo: String,
        path: String,
        content: String,
        message: String,
        pat: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            // Check if repository exists
            if (!checkRepoExists(username, repo, pat)) {
                android.util.Log.e("GitHubService", "Repository $repo doesn't exist. Please create it manually on GitHub.")
                return@withContext false
            }

            // Encode content to base64
            val base64Content = Base64.getEncoder().encodeToString(content.toByteArray())

            // Check if file exists to get SHA
            val existingSha = getFileSha(username, repo, path, pat)

            // Create JSON payload
            val jsonPayload = JSONObject().apply {
                put("message", message)
                put("content", base64Content)
                existingSha?.let { put("sha", it) }
            }

            // Make API request
            val url = "https://api.github.com/repos/$username/$repo/contents/$path"
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .header("X-GitHub-Api-Version", "2022-11-28")
                .put(jsonPayload.toString().toRequestBody(jsonMediaType))
                .build()

            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful

            if (!success) {
                android.util.Log.e("GitHubService", "GitHub API error: ${response.code} - ${response.body?.string()}")
            }

            response.close()
            success
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Failed to commit to GitHub: ${e.message}", e)
            false
        }
    }

    private fun checkRepoExists(username: String, repo: String, pat: String): Boolean {
        return try {
            val url = "https://api.github.com/repos/$username/$repo"
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .get()
                .build()

            val response = httpClient.newCall(request).execute()
            val exists = response.isSuccessful
            response.close()
            exists
        } catch (e: Exception) {
            false
        }
    }

    private fun createRepository(repo: String, pat: String): Boolean {
        return try {
            val jsonPayload = JSONObject().apply {
                put("name", repo)
                put("description", "Ralph-CoS Daily Audit Logs")
                put("private", false)
                put("auto_init", true)
            }

            val request = Request.Builder()
                .url("https://api.github.com/user/repos")
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .header("X-GitHub-Api-Version", "2022-11-28")
                .post(jsonPayload.toString().toRequestBody(jsonMediaType))
                .build()

            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful

            if (!success) {
                android.util.Log.e("GitHubService", "Failed to create repo: ${response.code} - ${response.body?.string()}")
            }

            response.close()
            success
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Error creating repository: ${e.message}", e)
            false
        }
    }

    private fun getFileSha(username: String, repo: String, path: String, pat: String): String? {
        return try {
            val url = "https://api.github.com/repos/$username/$repo/contents/$path"
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .get()
                .build()

            val response = httpClient.newCall(request).execute()
            if (response.isSuccessful) {
                val body = response.body?.string()
                val json = JSONObject(body ?: "{}")
                response.close()
                val sha = json.optString("sha")
                if (sha.isNotEmpty()) sha else null
            } else {
                response.close()
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getFileContent(username: String, repo: String, path: String, pat: String): Pair<String, String?> {
        return try {
            val url = "https://api.github.com/repos/$username/$repo/contents/$path"
            val request = Request.Builder()
                .url(url)
                .header("Authorization", "Bearer $pat")
                .header("Accept", "application/vnd.github+json")
                .get()
                .build()

            val response = httpClient.newCall(request).execute()
            if (response.isSuccessful) {
                val body = response.body?.string()
                val json = JSONObject(body ?: "{}")
                response.close()

                val sha = json.optString("sha")
                val base64Content = json.optString("content", "")

                // Decode base64 content (remove newlines first)
                val content = if (base64Content.isNotEmpty()) {
                    val cleanBase64 = base64Content.replace("\n", "")
                    String(Base64.getDecoder().decode(cleanBase64))
                } else {
                    ""
                }

                Pair(content, if (sha.isNotEmpty()) sha else null)
            } else {
                response.close()
                Pair("", null)
            }
        } catch (e: Exception) {
            android.util.Log.e("GitHubService", "Failed to get file content: ${e.message}", e)
            Pair("", null)
        }
    }

    companion object {
        private const val KEY_PAT = "github_pat"
        private const val KEY_USERNAME = "github_username"
    }
}
