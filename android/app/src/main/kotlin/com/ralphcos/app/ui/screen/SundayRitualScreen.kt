package com.ralphcos.app.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Lock
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
import com.ralphcos.app.data.repository.VowRepository
import com.ralphcos.app.service.GeminiService
import com.ralphcos.app.service.GitHubService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.temporal.TemporalAdjusters

/**
 * Sunday Ritual Screen
 *
 * Sonntag 13:00-22:00: Wochenplanung
 * - Nur freigeschaltet wenn ALLE Wochenziele der vergangenen Woche erledigt
 * - Weekly Review: Was lief gut/schlecht
 * - Anti-Vision / Vision Check
 * - Nächste Woche planen
 * - Weekly Integrity Score
 */

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SundayRitualScreen(
    vowRepository: VowRepository,
    integrityRepository: IntegrityRepository,
    githubService: GitHubService,
    geminiService: GeminiService,
    onRitualCompleted: () -> Unit = {}
) {
    val viewModel: SundayRitualViewModel = viewModel()
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadWeeklyState(vowRepository, integrityRepository)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("SUNDAY RITUAL") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
        ) {
            // Time window indicator
            TimeWindowCard(
                isInWindow = uiState.isInTimeWindow,
                currentTime = uiState.currentTime
            )

            Spacer(modifier = Modifier.height(24.dp))

            if (!uiState.isInTimeWindow) {
                // Not in time window
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = Color(0xFF4D4D1A)
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = "Locked",
                            modifier = Modifier.size(64.dp),
                            tint = Color(0xFFFFA500)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "RITUAL NICHT VERFÜGBAR",
                            style = MaterialTheme.typography.headlineMedium,
                            color = Color(0xFFFFA500),
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Komm zurück Sonntag 13:00-22:00",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )
                    }
                }
                return@Scaffold
            }

            if (!uiState.weeklyGoalsComplete) {
                // Goals not complete - locked
                WeeklyGoalsLockedCard(
                    completedDays = uiState.completedDaysThisWeek,
                    totalDays = 7,
                    missingDays = 7 - uiState.completedDaysThisWeek
                )
                return@Scaffold
            }

            if (uiState.isCompleted) {
                // Already completed
                RitualCompletedCard()
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = onRitualCompleted,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.Green,
                        contentColor = Color.Black
                    )
                ) {
                    Text("ZURÜCK")
                }
                return@Scaffold
            }

            // Weekly Score Card
            WeeklyScoreCard(
                score = uiState.weeklyScore,
                breaches = uiState.weeklyBreaches,
                streak = uiState.currentStreak
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Planning Sections
            Text(
                text = "WOCHENPLANUNG",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(PLANNING_SECTIONS) { section ->
                    PlanningSectionCard(
                        section = section,
                        completed = uiState.planningSections[section.id] ?: false,
                        onToggle = {
                            viewModel.togglePlanningSection(section.id)
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Complete button
            val allComplete = uiState.planningSections.all { it.value }

            Button(
                onClick = {
                    viewModel.completeRitual(integrityRepository, githubService)
                    onRitualCompleted()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = allComplete,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (allComplete) Color.Green else Color.Gray,
                    contentColor = Color.Black
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Complete"
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("RITUAL ABSCHLIESSEN")
            }

            if (!allComplete) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Vervollständige alle Planungs-Sections",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Red,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

@Composable
private fun TimeWindowCard(isInWindow: Boolean, currentTime: LocalTime) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isInWindow) Color(0xFF1A4D1A) else Color(0xFF4D1A1A)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "SONNTAG 13:00-22:00",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
                Text(
                    text = currentTime.format(DateTimeFormatter.ofPattern("HH:mm")),
                    style = MaterialTheme.typography.headlineMedium,
                    color = if (isInWindow) Color.Green else Color.Red
                )
            }
            Icon(
                imageVector = if (isInWindow) Icons.Default.Check else Icons.Default.Lock,
                contentDescription = if (isInWindow) "Open" else "Locked",
                modifier = Modifier.size(32.dp),
                tint = if (isInWindow) Color.Green else Color.Red
            )
        }
    }
}

@Composable
private fun WeeklyGoalsLockedCard(completedDays: Int, totalDays: Int, missingDays: Int) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 3.dp,
                color = Color.Red,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF4D1A1A)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Lock,
                contentDescription = "Locked",
                modifier = Modifier.size(64.dp),
                tint = Color.Red
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "RITUAL GESPERRT",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.Red,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Diese Woche: $completedDays / $totalDays Tage erfüllt",
                style = MaterialTheme.typography.titleMedium,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Du hast $missingDays Tage verpasst.",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.Red
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = """
                    Sunday Ritual nur verfügbar bei 7/7 Tagen.

                    Keine Ausreden. Vollständige Woche oder nichts.
                """.trimIndent(),
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun WeeklyScoreCard(score: Double, breaches: Int, streak: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when {
                score >= 90 -> Color(0xFF1A4D1A)
                score >= 70 -> Color(0xFF4D4D1A)
                else -> Color(0xFF4D1A1A)
            }
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Text(
                text = "WOCHEN-SCORE",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Gray
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "${score.toInt()}/100",
                    style = MaterialTheme.typography.displayMedium,
                    color = when {
                        score >= 90 -> Color.Green
                        score >= 70 -> Color(0xFFFFA500)
                        else -> Color.Red
                    }
                )

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Breaches: $breaches",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )
                    Text(
                        text = "Streak: $streak Tage",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.Green
                    )
                }
            }
        }
    }
}

@Composable
private fun PlanningSectionCard(
    section: PlanningSection,
    completed: Boolean,
    onToggle: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = if (completed) Color.Green else MaterialTheme.colorScheme.outline,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (completed)
                Color(0xFF1A4D1A)
            else
                MaterialTheme.colorScheme.surface
        ),
        onClick = onToggle
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = completed,
                onCheckedChange = { onToggle() },
                colors = CheckboxDefaults.colors(
                    checkedColor = Color.Green,
                    uncheckedColor = Color.Gray
                )
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = section.title,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (completed) Color.Green else MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = section.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun RitualCompletedCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1A4D1A)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.CalendarMonth,
                contentDescription = "Complete",
                modifier = Modifier.size(64.dp),
                tint = Color.Green
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "WOCHENPLANUNG ABGESCHLOSSEN",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.Green,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Gute Woche voraus. Jetzt umsetzen.",
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF90EE90)
            )
        }
    }
}

// ViewModel
class SundayRitualViewModel : ViewModel() {

    data class UiState(
        val isInTimeWindow: Boolean = false,
        val currentTime: LocalTime = LocalTime.now(),
        val weeklyGoalsComplete: Boolean = false,
        val completedDaysThisWeek: Int = 0,
        val isCompleted: Boolean = false,
        val weeklyScore: Double = 100.0,
        val weeklyBreaches: Int = 0,
        val currentStreak: Int = 0,
        val planningSections: Map<String, Boolean> = emptyMap()
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    fun loadWeeklyState(vowRepository: VowRepository, integrityRepository: IntegrityRepository) {
        viewModelScope.launch {
            val currentTime = LocalTime.now()
            val currentDay = LocalDate.now().dayOfWeek
            val windowStart = LocalTime.of(13, 0)
            val windowEnd = LocalTime.of(22, 0)

            val isInWindow = currentDay == DayOfWeek.SUNDAY &&
                             currentTime.isAfter(windowStart) &&
                             currentTime.isBefore(windowEnd)

            // Get this week's start (Monday)
            val weekStart = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            val weekEnd = LocalDate.now()

            // Count completed days (days with both morning vow and evening claim)
            var completedDays = 0
            var currentDate = weekStart
            while (!currentDate.isAfter(weekEnd.minusDays(1))) { // Exclude today (Sunday)
                // Check if this day had both vow and claim
                val breachesOnDay = integrityRepository.getAllBreaches()
                    .filter { it.date == currentDate }
                    .filter { !it.repaired }
                    .filter {
                        it.type == com.ralphcos.app.data.entity.BreachType.MISSED_MORNING_VOW ||
                        it.type == com.ralphcos.app.data.entity.BreachType.MISSED_EVENING_CLAIM
                    }

                // Day is complete if no breaches for morning vow or evening claim
                if (breachesOnDay.isEmpty()) {
                    completedDays++
                }

                currentDate = currentDate.plusDays(1)
            }

            // Get weekly score
            val score = integrityRepository.calculateIntegrityScore(weekStart, weekEnd)
            val breaches = integrityRepository.getAllBreaches()
                .filter { it.date.isAfter(weekStart.minusDays(1)) && it.date.isBefore(weekEnd.plusDays(1)) }
                .filter { !it.repaired }

            // Get streak
            val streakState = integrityRepository.getOrCreateStreakState()

            // Initialize planning sections
            val sections = PLANNING_SECTIONS.associate { it.id to false }

            _uiState.value = _uiState.value.copy(
                isInTimeWindow = isInWindow,
                currentTime = currentTime,
                weeklyGoalsComplete = completedDays >= 6, // 6 days (Mon-Sat)
                completedDaysThisWeek = completedDays,
                weeklyScore = score.score,
                weeklyBreaches = breaches.size,
                currentStreak = streakState.currentStreak,
                planningSections = sections
            )
        }
    }

    fun togglePlanningSection(sectionId: String) {
        val updated = _uiState.value.planningSections.toMutableMap()
        updated[sectionId] = !(updated[sectionId] ?: false)
        _uiState.value = _uiState.value.copy(planningSections = updated)
    }

    fun completeRitual(integrityRepository: IntegrityRepository, githubService: GitHubService) {
        viewModelScope.launch {
            // Save planning data
            val planningData = _uiState.value.planningSections.entries
                .joinToString("\n") { "${it.key}: ${it.value}" }

            // Commit to GitHub
            githubService.commitAuditFiles(
                LocalDate.now(),
                "Sunday Ritual Planning:\n$planningData\n\nWeekly Score: ${_uiState.value.weeklyScore}"
            )

            _uiState.value = _uiState.value.copy(isCompleted = true)
        }
    }
}

data class PlanningSection(
    val id: String,
    val title: String,
    val description: String
)

private val PLANNING_SECTIONS = listOf(
    PlanningSection(
        "weekly_review",
        "Weekly Review",
        "Was lief gut? Was lief schlecht? Lessons learned."
    ),
    PlanningSection(
        "anti_vision_check",
        "Anti-Vision Check",
        "Welche Verhaltensweisen führen zur Anti-Vision? Was vermieden?"
    ),
    PlanningSection(
        "vision_alignment",
        "Vision Alignment",
        "Bin ich auf dem Weg zur Vision? Concrete actions identifiziert?"
    ),
    PlanningSection(
        "next_week_goals",
        "Nächste Woche: Ziele",
        "3-5 konkrete Ziele für die kommende Woche definiert."
    ),
    PlanningSection(
        "daily_levers",
        "Daily Levers Review",
        "Welche Levers funktionieren? Welche nicht? Adjustments?"
    ),
    PlanningSection(
        "obstacle_prep",
        "Obstacle Preparation",
        "Welche Hindernisse erwarte ich? Wie werde ich sie überwinden?"
    )
)
