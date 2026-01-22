package com.ralphcos.app.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Check
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
import com.ralphcos.app.data.entity.Breach
import com.ralphcos.app.data.entity.BreachType
import com.ralphcos.app.data.repository.IntegrityRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * Repair Mode Screen
 *
 * Allows users to repair unrepaired breaches with -0.5 score penalty per repair
 * Shows list of breaches with option to repair each one
 */

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RepairModeScreen(
    integrityRepository: IntegrityRepository,
    onNavigateBack: () -> Unit
) {
    val viewModel: RepairModeViewModel = viewModel()
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadBreaches(integrityRepository)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("REPAIR MODE") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = Color(0xFFFFA500) // Orange for repair mode
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
            // Info Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = Color(0xFF4D4D1A) // Dark yellow/orange
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = "Warning",
                        modifier = Modifier.size(48.dp),
                        tint = Color(0xFFFFA500)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(
                            text = "REPAIR PENALTY",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color(0xFFFFA500)
                        )
                        Text(
                            text = "Each repair: -0.5 to Integrity Score",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White
                        )
                        Text(
                            text = "Repair = acknowledging failure + cost",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                StatCard(
                    label = "Unrepaired",
                    value = "${uiState.unrepairedCount}",
                    color = Color.Red
                )
                StatCard(
                    label = "Repaired",
                    value = "${uiState.repairedCount}",
                    color = Color.Green
                )
                StatCard(
                    label = "Total Penalty",
                    value = "-${uiState.repairedCount * 0.5}",
                    color = Color(0xFFFFA500)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Breaches List
            Text(
                text = "UNREPAIRED BREACHES",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            if (uiState.unrepairedBreaches.isEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF1A4D1A))
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = "No breaches",
                            modifier = Modifier.size(64.dp),
                            tint = Color.Green
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "NO UNREPAIRED BREACHES",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color.Green,
                            textAlign = TextAlign.Center
                        )
                        Text(
                            text = "Your integrity is intact",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFF90EE90)
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(uiState.unrepairedBreaches) { breach ->
                        BreachCard(
                            breach = breach,
                            onRepair = {
                                viewModel.repairBreach(integrityRepository, breach)
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StatCard(label: String, value: String, color: Color) {
    Card(
        modifier = Modifier.width(100.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium,
                color = color
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun BreachCard(breach: Breach, onRepair: () -> Unit) {
    val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = Color.Red,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF4D1A1A) // Dark red
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = when (breach.type) {
                            BreachType.MISSED_MORNING_VOW -> "MISSED MORNING VOW"
                            BreachType.MISSED_EVENING_CLAIM -> "MISSED EVENING CLAIM"
                            BreachType.AUDIT_MISMATCH -> "AUDIT MISMATCH"
                            BreachType.IGNORED_INTERRUPTION -> "IGNORED INTERRUPTION"
                        },
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.Red
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = breach.date.format(formatter),
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = breach.reason,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = onRepair,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFFFA500),
                    contentColor = Color.Black
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Build,
                    contentDescription = "Repair",
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("REPAIR (-0.5 PENALTY)")
            }
        }
    }
}

// ViewModel
class RepairModeViewModel : ViewModel() {

    data class UiState(
        val unrepairedBreaches: List<Breach> = emptyList(),
        val unrepairedCount: Int = 0,
        val repairedCount: Int = 0
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    fun loadBreaches(integrityRepository: IntegrityRepository) {
        viewModelScope.launch {
            val breaches = integrityRepository.getAllBreaches()
            val unrepaired = breaches.filter { !it.repaired }
            val repaired = breaches.filter { it.repaired }

            _uiState.value = _uiState.value.copy(
                unrepairedBreaches = unrepaired.sortedByDescending { it.date },
                unrepairedCount = unrepaired.size,
                repairedCount = repaired.size
            )
        }
    }

    fun repairBreach(integrityRepository: IntegrityRepository, breach: Breach) {
        viewModelScope.launch {
            integrityRepository.repairBreach(breach.id)
            // Reload breaches after repair
            loadBreaches(integrityRepository)
        }
    }
}
