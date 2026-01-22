package com.ralphcos.app.ui.component

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.ralphcos.app.data.entity.IntegrityScore
import com.ralphcos.app.data.entity.StreakState
import com.ralphcos.app.data.repository.IntegrityRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

/**
 * Feature 6: Adaptive Identity Mirror
 *
 * Pinned Card (über Uhr): Stufen
 * - Normal (grün)
 * - Caution (bernstein)
 * - RED 1 (langsam pulsierend #991B1B)
 * - RED 2 (schnell + Shake)
 *
 * Trigger: Breaches/Debt-Tage
 * Config: Intensity (low/medium/high/off)
 */

enum class MirrorState {
    NORMAL,      // Green - All good
    CAUTION,     // Amber - Warning
    RED_LEVEL_1, // Red slow pulse - Debt 1-3 days
    RED_LEVEL_2  // Red fast pulse + shake - Debt 4+ days
}

@Composable
fun IdentityMirror(
    integrityRepository: IntegrityRepository,
    modifier: Modifier = Modifier
) {
    val viewModel: IdentityMirrorViewModel = viewModel()

    LaunchedEffect(Unit) {
        viewModel.observeIntegrityState(integrityRepository)
    }

    val uiState by viewModel.uiState.collectAsState()

    val mirrorState = determineMirrorState(
        breachCount = uiState.breachCount,
        debtDays = uiState.debtDays,
        streakDays = uiState.streakDays
    )

    MirrorCard(
        state = mirrorState,
        score = uiState.score,
        streakDays = uiState.streakDays,
        debtDays = uiState.debtDays,
        breachCount = uiState.breachCount,
        modifier = modifier
    )
}

@Composable
private fun MirrorCard(
    state: MirrorState,
    score: Double,
    streakDays: Int,
    debtDays: Int,
    breachCount: Int,
    modifier: Modifier = Modifier
) {
    // Animation for pulse effect
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseAlpha = infiniteTransition.animateFloat(
        initialValue = 0.6f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = when (state) {
                    MirrorState.RED_LEVEL_1 -> 2000 // Slow pulse
                    MirrorState.RED_LEVEL_2 -> 800  // Fast pulse
                    else -> 2000
                },
                easing = EaseInOut
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_alpha"
    )

    // Shake animation for RED_LEVEL_2
    val shakeOffset = infiniteTransition.animateFloat(
        initialValue = -2f,
        targetValue = 2f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 100,
                easing = LinearEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "shake"
    )

    val cardColor = when (state) {
        MirrorState.NORMAL -> Color(0xFF1A4D1A)
        MirrorState.CAUTION -> Color(0xFF4D3D1A)
        MirrorState.RED_LEVEL_1 -> Color(0xFF991B1B).copy(alpha = pulseAlpha.value)
        MirrorState.RED_LEVEL_2 -> Color(0xFF991B1B).copy(alpha = pulseAlpha.value)
    }

    val borderColor = when (state) {
        MirrorState.NORMAL -> Color.Green
        MirrorState.CAUTION -> Color(0xFFFFA500)
        MirrorState.RED_LEVEL_1 -> Color.Red
        MirrorState.RED_LEVEL_2 -> Color.Red
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (state == MirrorState.RED_LEVEL_2) {
                    Modifier.offset(x = shakeOffset.value.dp)
                } else Modifier
            )
            .border(
                width = 3.dp,
                color = borderColor,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(containerColor = cardColor)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // State Badge
            Text(
                text = when (state) {
                    MirrorState.NORMAL -> "● NORMAL"
                    MirrorState.CAUTION -> "▲ CAUTION"
                    MirrorState.RED_LEVEL_1 -> "⚠ RED LEVEL 1"
                    MirrorState.RED_LEVEL_2 -> "🔥 RED LEVEL 2"
                },
                style = MaterialTheme.typography.titleLarge,
                color = when (state) {
                    MirrorState.NORMAL -> Color.Green
                    MirrorState.CAUTION -> Color(0xFFFFA500)
                    MirrorState.RED_LEVEL_1 -> Color.Red
                    MirrorState.RED_LEVEL_2 -> Color.Red
                },
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Score Display
            Text(
                text = "INTEGRITY SCORE",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray
            )
            Text(
                text = String.format("%.1f", score),
                style = MaterialTheme.typography.headlineLarge,
                color = when {
                    score >= 85 -> Color.Green
                    score >= 70 -> Color(0xFFFFA500)
                    else -> Color.Red
                }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Stats Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatItem("STREAK", streakDays.toString(), Color.Green)
                StatItem("BREACHES", breachCount.toString(), Color.Red)
                StatItem("DEBT DAYS", debtDays.toString(), Color(0xFFFFA500))
            }

            // Warning Message
            if (state != MirrorState.NORMAL) {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = when (state) {
                        MirrorState.CAUTION -> "⚠ Approaching integrity threshold"
                        MirrorState.RED_LEVEL_1 -> "🔴 BREACH DETECTED - Repair required"
                        MirrorState.RED_LEVEL_2 -> "🔥 CRITICAL: Extended debt period"
                        else -> ""
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun StatItem(label: String, value: String, color: Color) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            color = color
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = Color.Gray
        )
    }
}

private fun determineMirrorState(
    breachCount: Int,
    debtDays: Int,
    streakDays: Int
): MirrorState {
    return when {
        debtDays >= 7 -> MirrorState.RED_LEVEL_2  // >7 days debt = RED 2
        debtDays >= 3 -> MirrorState.RED_LEVEL_1  // 3-6 days debt = RED 1
        breachCount >= 3 -> MirrorState.CAUTION   // 3+ breaches = Caution
        streakDays >= 20 -> MirrorState.NORMAL    // Good streak = Normal
        debtDays > 0 -> MirrorState.CAUTION       // Any debt = Caution
        else -> MirrorState.NORMAL
    }
}

// ViewModel
class IdentityMirrorViewModel : ViewModel() {

    data class UiState(
        val score: Double = 100.0,
        val streakDays: Int = 0,
        val breachCount: Int = 0,
        val debtDays: Int = 0
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    fun observeIntegrityState(integrityRepository: IntegrityRepository) {
        viewModelScope.launch {
            combine(
                integrityRepository.observeLatestScore(),
                integrityRepository.observeStreakState()
            ) { score, streak ->
                _uiState.value = UiState(
                    score = score?.score ?: 100.0,
                    streakDays = streak?.currentStreak ?: 0,
                    breachCount = score?.breachCount ?: 0,
                    debtDays = score?.debtDays ?: 0
                )
            }.collect {}
        }
    }
}
