package com.ralphcos.app.ui.screen

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.ralphcos.app.data.repository.IntegrityRepository
import com.ralphcos.app.service.GeminiService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * 30-Day Challenge Gate Screen (Feature 9)
 *
 * Shows progress through 30-day integrity challenge
 * Provides AI-generated feedback based on performance
 * Tracks completion and unlocks advanced features
 */

@Composable
fun ChallengeGateScreen(
    integrityRepository: IntegrityRepository,
    geminiService: GeminiService,
    challengeDao: com.ralphcos.app.data.dao.ChallengeDao,
    onStartChallenge: () -> Unit = {},
    onContinue: () -> Unit = {}
) {
    val viewModel: ChallengeGateViewModel = viewModel()
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadChallengeState(integrityRepository, geminiService, challengeDao)
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp)
        ) {
            // Header
            Text(
                text = "30-DAY CHALLENGE",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = if (uiState.isActive) "AKTIV" else "BEREIT ZU STARTEN",
                style = MaterialTheme.typography.bodyLarge,
                color = if (uiState.isActive) Color.Green else Color(0xFFFFA500)
            )

            Spacer(modifier = Modifier.height(32.dp))

            if (uiState.isActive) {
                // Active challenge UI
                ActiveChallengeCard(
                    day = uiState.currentDay,
                    score = uiState.currentScore,
                    breaches = uiState.totalBreaches,
                    streak = uiState.streakDays
                )

                Spacer(modifier = Modifier.height(24.dp))

                // AI Feedback
                if (uiState.aiFeedback.isNotEmpty()) {
                    AiFeedbackCard(feedback = uiState.aiFeedback)
                    Spacer(modifier = Modifier.height(24.dp))
                }

                // Progress to completion
                if (uiState.currentDay >= 30) {
                    ChallengeCompleteCard(
                        finalScore = uiState.currentScore,
                        totalBreaches = uiState.totalBreaches
                    )
                } else {
                    // Continue button
                    Button(
                        onClick = onContinue,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.Green,
                            contentColor = Color.Black
                        )
                    ) {
                        Text("WEITER ZUR APP")
                    }
                }
            } else {
                // Challenge introduction
                ChallengeIntroCard()

                Spacer(modifier = Modifier.height(24.dp))

                // Rules
                RulesCard()

                Spacer(modifier = Modifier.height(32.dp))

                // Start button
                Button(
                    onClick = {
                        viewModel.startSimpleChallenge(challengeDao)
                        onStartChallenge()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(72.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.Green,
                        contentColor = Color.Black
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.Flag,
                        contentDescription = "Start",
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "CHALLENGE STARTEN",
                        style = MaterialTheme.typography.labelLarge
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedButton(
                    onClick = onContinue,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                ) {
                    Text("SPÄTER STARTEN")
                }
            }
        }
    }
}

@Composable
private fun ActiveChallengeCard(
    day: Int,
    score: Double,
    breaches: Int,
    streak: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when {
                score >= 90 -> Color(0xFF1A4D1A) // Dark green
                score >= 70 -> Color(0xFF4D4D1A) // Dark yellow
                else -> Color(0xFF4D1A1A) // Dark red
            }
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Day counter with animation
            val infiniteTransition = rememberInfiniteTransition(label = "pulse")
            val alpha = infiniteTransition.animateFloat(
                initialValue = 0.7f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(1500),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "alpha"
            )

            Text(
                text = "TAG $day / 30",
                style = MaterialTheme.typography.displayMedium,
                color = Color.White.copy(alpha = alpha.value)
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatColumn("SCORE", "${score.toInt()}/100", getScoreColor(score))
                StatColumn("BREACHES", "$breaches", Color.Red)
                StatColumn("STREAK", "$streak", Color.Green)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Progress bar
            LinearProgressIndicator(
                progress = day / 30f,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                color = Color.Green,
                trackColor = Color.Gray,
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "${30 - day} Tage verbleibend",
                style = MaterialTheme.typography.bodySmall,
                color = Color.White
            )
        }
    }
}

@Composable
private fun StatColumn(label: String, value: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineMedium,
            color = color
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = Color.Gray
        )
    }
}

private fun getScoreColor(score: Double): Color = when {
    score >= 90 -> Color.Green
    score >= 70 -> Color(0xFFFFA500)
    else -> Color.Red
}

@Composable
private fun AiFeedbackCard(feedback: String) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = Color(0xFFFFA500),
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF2D2D2D)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = "AI Feedback",
                    tint = Color(0xFFFFA500),
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "RALPH'S FEEDBACK",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color(0xFFFFA500)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = feedback,
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White,
                lineHeight = MaterialTheme.typography.bodyLarge.lineHeight
            )
        }
    }
}

@Composable
private fun ChallengeCompleteCard(finalScore: Double, totalBreaches: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (finalScore >= 80) Color(0xFF1A4D1A) else Color(0xFF4D4D1A)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.EmojiEvents,
                contentDescription = "Complete",
                modifier = Modifier.size(80.dp),
                tint = if (finalScore >= 80) Color(0xFFFFD700) else Color(0xFFFFA500)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "CHALLENGE ABGESCHLOSSEN",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.White,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Final Score: ${finalScore.toInt()}/100",
                style = MaterialTheme.typography.displaySmall,
                color = getScoreColor(finalScore)
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Total Breaches: $totalBreaches",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = if (finalScore >= 80) {
                    "Exzellente Leistung. Du hast bewiesen, dass du Disziplin hast."
                } else {
                    "Challenge abgeschlossen, aber mit Schwächen. Nächstes Mal besser."
                },
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun ChallengeIntroCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Text(
                text = "DIE CHALLENGE",
                style = MaterialTheme.typography.titleLarge,
                color = Color.Green
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "30 Tage. Keine Ausreden. Maximale Integrität.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = """
                    Diese Challenge testet deine Disziplin über 30 Tage:

                    • Tägliche Morning Vows (05:00-09:00)
                    • Evening Rituals (ab 17:00)
                    • Pattern Interruptions beachten
                    • GitHub Audit täglich

                    Ralph (AI) wird dich täglich bewerten. Brutal ehrlich.
                """.trimIndent(),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun RulesCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF4D1A1A) // Dark red
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Text(
                text = "REGELN",
                style = MaterialTheme.typography.titleLarge,
                color = Color.Red
            )

            Spacer(modifier = Modifier.height(12.dp))

            val rules = listOf(
                "Jeden Tag Morning Vow bis 09:00 oder Streak bricht",
                "Jeden Tag Evening Ritual ab 17:00 mit GitHub Commit",
                "Breaches = Score-Penalty (exponentiell)",
                "Repairs möglich, aber -0.5 pro Repair",
                "Nach 30 Tagen: Final Score bestimmt Erfolg (80+ = bestanden)"
            )

            rules.forEach { rule ->
                Row(
                    modifier = Modifier.padding(vertical = 4.dp)
                ) {
                    Text("• ", color = Color.Red)
                    Text(
                        text = rule,
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )
                }
            }
        }
    }
}

// ViewModel
class ChallengeGateViewModel : ViewModel() {

    data class UiState(
        val isActive: Boolean = false,
        val currentDay: Int = 0,
        val currentScore: Double = 100.0,
        val totalBreaches: Int = 0,
        val streakDays: Int = 0,
        val aiFeedback: String = "",
        val startDate: LocalDate? = null
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    fun loadChallengeState(integrityRepository: IntegrityRepository, geminiService: GeminiService, challengeDao: com.ralphcos.app.data.dao.ChallengeDao) {
        viewModelScope.launch {
            // Load active challenge from database
            val activeChallenge = challengeDao.getActiveChallenge()

            if (activeChallenge != null) {
                val currentDay = ChronoUnit.DAYS.between(activeChallenge.startDate, LocalDate.now()).toInt() + 1

                // Load integrity state
                val score = integrityRepository.getLatestScore()
                val breaches = integrityRepository.getAllBreaches()
                    .filter { it.date.isAfter(activeChallenge.startDate.minusDays(1)) }
                    .filter { !it.repaired }

                val streakState = integrityRepository.getOrCreateStreakState()

                // Generate AI feedback every 7 days
                val feedback = if (currentDay % 7 == 0) {
                    geminiService.generateChallengeFeedback(
                        currentDay,
                        breaches.size,
                        score?.score ?: 100.0
                    )
                } else {
                    ""
                }

                _uiState.value = _uiState.value.copy(
                    isActive = true,
                    currentDay = currentDay,
                    currentScore = score?.score ?: 100.0,
                    totalBreaches = breaches.size,
                    streakDays = streakState.currentStreak,
                    aiFeedback = feedback,
                    startDate = activeChallenge.startDate
                )
            }
        }
    }

    fun startSimpleChallenge(challengeDao: com.ralphcos.app.data.dao.ChallengeDao) {
        viewModelScope.launch {
            // Create simple challenge entry without challenge texts
            val challenge = com.ralphcos.app.data.entity.Challenge(
                startDate = LocalDate.now(),
                challenges = emptyList(), // No challenge texts needed
                isActive = true,
                completedDays = 0
            )
            challengeDao.insert(challenge)

            // Mark as active
            _uiState.value = _uiState.value.copy(
                isActive = true,
                startDate = LocalDate.now(),
                currentDay = 1
            )
        }
    }
}
