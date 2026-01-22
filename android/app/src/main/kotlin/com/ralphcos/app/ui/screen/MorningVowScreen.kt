package com.ralphcos.app.ui.screen

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
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
import com.ralphcos.app.data.entity.DailyVow
import com.ralphcos.app.data.repository.VowRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

/**
 * Feature 1: Morning Vow / Check-in Screen
 *
 * 05:00–09:00 CET Window
 * Select/Confirm Daily Levers:
 * - Mydealz
 * - Duolingo
 * - E-Mails
 * - X-Synthese
 * - Sport
 * - Jobsuche
 * - Custom
 *
 * Check-in bis 09:00 → grüner Status
 * Danach → INTEGRITY_DEBT + Streak-Risiko
 */

@Composable
fun MorningVowScreen(
    vowRepository: VowRepository,
    onVowCompleted: () -> Unit = {}
) {
    val viewModel: MorningVowViewModel = viewModel()
    val uiState by viewModel.uiState.collectAsState()
    val currentTime = remember { mutableStateOf(LocalTime.now()) }

    LaunchedEffect(Unit) {
        viewModel.loadTodayVow(vowRepository)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Timer Display
        TimeWindowIndicator(currentTime.value)

        Spacer(modifier = Modifier.height(32.dp))

        // Title
        Text(
            text = "MORNING VOW",
            style = MaterialTheme.typography.headlineLarge,
            color = if (uiState.isCompleted) Color.Green else MaterialTheme.colorScheme.onBackground
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, dd.MM.yyyy")),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(32.dp))

        if (uiState.isCompleted) {
            // Completed State
            CompletedVowCard(uiState.todayVow!!)
        } else {
            // Lever Selection
            Text(
                text = "SELECT YOUR DAILY LEVERS",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(uiState.availableLevers) { lever ->
                    LeverCheckbox(
                        lever = lever,
                        checked = uiState.selectedLevers.contains(lever),
                        onCheckedChange = { checked ->
                            viewModel.toggleLever(lever, checked)
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Complete Button
            Button(
                onClick = {
                    viewModel.completeMorningVow(vowRepository)
                    onVowCompleted()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = uiState.selectedLevers.isNotEmpty() && !uiState.isCompleted,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Green,
                    contentColor = Color.Black,
                    disabledContainerColor = Color.Gray
                )
            ) {
                Text(
                    text = "COMPLETE VOW",
                    style = MaterialTheme.typography.labelLarge
                )
            }
        }
    }
}

@Composable
private fun TimeWindowIndicator(currentTime: LocalTime) {
    val windowStart = LocalTime.of(5, 0)
    val windowEnd = LocalTime.of(9, 0)
    val isInWindow = currentTime.isAfter(windowStart) && currentTime.isBefore(windowEnd)

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isInWindow) Color(0xFF1A4D1A) else Color(0xFF4D1A1A)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "CURRENT TIME",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray
            )
            Text(
                text = currentTime.format(DateTimeFormatter.ofPattern("HH:mm:ss")),
                style = MaterialTheme.typography.headlineMedium,
                color = if (isInWindow) Color.Green else Color.Red
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = if (isInWindow) "WINDOW OPEN (05:00-09:00)" else "⚠ WINDOW CLOSED",
                style = MaterialTheme.typography.bodyMedium,
                color = if (isInWindow) Color.Green else Color.Red
            )
        }
    }
}

@Composable
private fun LeverCheckbox(
    lever: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = if (checked) Color.Green else MaterialTheme.colorScheme.outline,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (checked) Color(0xFF1A4D1A) else MaterialTheme.colorScheme.surface
        ),
        onClick = { onCheckedChange(!checked) }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = checked,
                onCheckedChange = onCheckedChange,
                colors = CheckboxDefaults.colors(
                    checkedColor = Color.Green,
                    uncheckedColor = Color.Gray
                )
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = lever,
                style = MaterialTheme.typography.bodyLarge,
                color = if (checked) Color.Green else MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun CompletedVowCard(vow: DailyVow) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF1A4D1A))
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = "Completed",
                modifier = Modifier.size(64.dp),
                tint = Color.Green
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "VOW COMPLETED",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.Green,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Completed at: ${vow.completedAt?.toString() ?: ""}",
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF90EE90)
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Active Levers: ${vow.levers.joinToString(", ")}",
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF90EE90),
                textAlign = TextAlign.Center
            )
        }
    }
}

// ViewModel
class MorningVowViewModel : ViewModel() {

    data class UiState(
        val todayVow: DailyVow? = null,
        val isCompleted: Boolean = false,
        val availableLevers: List<String> = DEFAULT_LEVERS,
        val selectedLevers: Set<String> = emptySet(),
        val isLoading: Boolean = false
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    fun loadTodayVow(vowRepository: VowRepository) {
        viewModelScope.launch {
            vowRepository.observeTodayVow().collect { vow ->
                _uiState.value = _uiState.value.copy(
                    todayVow = vow,
                    isCompleted = vow?.completed ?: false,
                    selectedLevers = vow?.levers?.toSet() ?: emptySet()
                )
            }
        }
    }

    fun toggleLever(lever: String, checked: Boolean) {
        val current = _uiState.value.selectedLevers.toMutableSet()
        if (checked) {
            current.add(lever)
        } else {
            current.remove(lever)
        }
        _uiState.value = _uiState.value.copy(selectedLevers = current)
    }

    fun completeMorningVow(vowRepository: VowRepository) {
        viewModelScope.launch {
            val levers = _uiState.value.selectedLevers.toList()
            if (levers.isNotEmpty()) {
                vowRepository.createTodayVow(levers)
                vowRepository.completeMorningVow()
            }
        }
    }

    companion object {
        private val DEFAULT_LEVERS = listOf(
            "Mydealz",
            "Duolingo",
            "E-Mails",
            "X-Synthese",
            "Sport",
            "Jobsuche"
        )
    }
}
