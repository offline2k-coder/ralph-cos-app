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
import com.ralphcos.app.data.entity.EveningClaim
import com.ralphcos.app.data.repository.VowRepository
import com.ralphcos.app.service.GitHubService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

/**
 * Feature 3: Evening Synthesis / Zero-Check Ritual
 *
 * Ab 17:00: Mantra + 5 Reflexions-Items
 * - Did I keep vow?
 * - What did I avoid?
 * - Inbox Zero
 * - Task Zero
 * - Guilt Zero
 *
 * Button "COMPLETE EVENING RITUAL"
 * Unvollständig → Button disabled oder Repair-Modus
 * Complete → Final Claim speichern + Git-Commit-Vorbereitung
 */

@Composable
fun EveningRitualScreen(
    vowRepository: VowRepository,
    githubService: GitHubService,
    onRitualCompleted: () -> Unit = {}
) {
    val viewModel: EveningRitualViewModel = viewModel()
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadTodayClaim(vowRepository)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Time Indicator
        EveningTimeIndicator()

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "EVENING SYNTHESIS",
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
            CompletedRitualCard()
        } else {
            // Mantra Section
            MantraCard(
                completed = uiState.mantraCompleted,
                onToggle = { viewModel.toggleMantra() }
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Reflection Items
            Text(
                text = "ZERO-CHECK RITUAL",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(REFLECTION_ITEMS.entries.toList()) { (key, label) ->
                    ReflectionCheckbox(
                        label = label,
                        checked = uiState.reflectionItems[key] ?: false,
                        onCheckedChange = { checked ->
                            viewModel.toggleReflectionItem(key, checked)
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Complete Button
            val allComplete = uiState.mantraCompleted && uiState.reflectionItems.all { it.value }

            Button(
                onClick = {
                    viewModel.completeEveningRitual(vowRepository, githubService)
                    onRitualCompleted()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = allComplete && !uiState.isCompleted,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (allComplete) Color.Green else Color.Gray,
                    contentColor = Color.Black
                )
            ) {
                Text(
                    text = "COMPLETE EVENING RITUAL",
                    style = MaterialTheme.typography.labelLarge
                )
            }

            if (!allComplete) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Complete all items to proceed",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Red,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun EveningTimeIndicator() {
    val currentTime = LocalTime.now()
    val windowStart = LocalTime.of(17, 0)
    val isWindowOpen = currentTime.isAfter(windowStart)

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isWindowOpen) Color(0xFF1A4D1A) else Color(0xFF4D4D1A)
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
                color = if (isWindowOpen) Color.Green else Color(0xFFFFA500)
            )
            Text(
                text = if (isWindowOpen) "RITUAL WINDOW OPEN (17:00+)" else "Opens at 17:00",
                style = MaterialTheme.typography.bodyMedium,
                color = if (isWindowOpen) Color.Green else Color(0xFFFFA500)
            )
        }
    }
}

@Composable
private fun MantraCard(
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
            containerColor = if (completed) Color(0xFF1A4D1A) else MaterialTheme.colorScheme.surface
        ),
        onClick = onToggle
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
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
                Text(
                    text = "DAILY MANTRA",
                    style = MaterialTheme.typography.titleLarge,
                    color = if (completed) Color.Green else MaterialTheme.colorScheme.onSurface
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "\"Integrität ist die einzige Währung.\"",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 48.dp)
            )
        }
    }
}

@Composable
private fun ReflectionCheckbox(
    label: String,
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
                text = label,
                style = MaterialTheme.typography.bodyLarge,
                color = if (checked) Color.Green else MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun CompletedRitualCard() {
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
                text = "EVENING RITUAL COMPLETE",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.Green,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Claim submitted for audit",
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF90EE90)
            )
        }
    }
}

// ViewModel
class EveningRitualViewModel : ViewModel() {

    data class UiState(
        val todayClaim: EveningClaim? = null,
        val isCompleted: Boolean = false,
        val mantraCompleted: Boolean = false,
        val reflectionItems: Map<String, Boolean> = emptyMap(),
        val vowId: Long? = null
    )

    private val _uiState = MutableStateFlow(
        UiState(reflectionItems = REFLECTION_ITEMS.keys.associateWith { false })
    )
    val uiState: StateFlow<UiState> = _uiState

    fun loadTodayClaim(vowRepository: VowRepository) {
        viewModelScope.launch {
            vowRepository.observeTodayClaim().collect { claim ->
                _uiState.value = _uiState.value.copy(
                    todayClaim = claim,
                    isCompleted = claim?.completed ?: false,
                    mantraCompleted = claim?.mantraCompleted ?: false,
                    reflectionItems = claim?.reflectionItems ?: REFLECTION_ITEMS.keys.associateWith { false }
                )
            }
        }

        viewModelScope.launch {
            vowRepository.observeTodayVow().collect { vow ->
                _uiState.value = _uiState.value.copy(vowId = vow?.id)
            }
        }
    }

    fun toggleMantra() {
        _uiState.value = _uiState.value.copy(
            mantraCompleted = !_uiState.value.mantraCompleted
        )
    }

    fun toggleReflectionItem(key: String, checked: Boolean) {
        val updated = _uiState.value.reflectionItems.toMutableMap()
        updated[key] = checked
        _uiState.value = _uiState.value.copy(reflectionItems = updated)
    }

    fun completeEveningRitual(vowRepository: VowRepository, githubService: GitHubService) {
        viewModelScope.launch {
            val vowId = _uiState.value.vowId ?: return@launch

            // Create claim
            val claimId = vowRepository.createEveningClaim(
                vowId = vowId,
                reflectionItems = _uiState.value.reflectionItems,
                mantraCompleted = _uiState.value.mantraCompleted
            )

            // Commit to GitHub
            val claimData = _uiState.value.reflectionItems.entries
                .joinToString("\n") { "${it.key}: ${it.value}" }

            val success = githubService.commitAuditFiles(LocalDate.now(), claimData)
            val gitSha = if (success) "local_commit" else null

            vowRepository.completeEveningClaim(claimId, gitSha)
        }
    }
}

private val REFLECTION_ITEMS = mapOf(
    "kept_vow" to "Did I keep my vow?",
    "avoided" to "What did I avoid today?",
    "inbox_zero" to "Inbox Zero achieved",
    "task_zero" to "Task Zero achieved",
    "guilt_zero" to "Guilt Zero achieved"
)
