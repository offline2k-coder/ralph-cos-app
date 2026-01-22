package com.ralphcos.app.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.ralphcos.app.service.GitHubService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

enum class MirrorIntensity {
    OFF,
    LOW,
    MEDIUM,
    HIGH
}

enum class SyncStatus {
    UNKNOWN,
    SYNCING,
    SUCCESS,
    ERROR
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    githubService: GitHubService,
    onNavigateBack: () -> Unit
) {
    val viewModel: SettingsViewModel = viewModel()

    LaunchedEffect(Unit) {
        viewModel.loadSettings(githubService)
    }

    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("SETTINGS") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // GitHub Integration Section
            item {
                SettingsSection(title = "GITHUB INTEGRATION") {
                    OutlinedTextField(
                        value = uiState.githubUsername,
                        onValueChange = { viewModel.updateUsername(it) },
                        label = { Text("GitHub Username") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Color.Green,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        )
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    OutlinedTextField(
                        value = uiState.githubPAT,
                        onValueChange = { viewModel.updatePAT(it) },
                        label = { Text("Personal Access Token") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        visualTransformation = if (uiState.showPAT)
                            VisualTransformation.None
                        else
                            PasswordVisualTransformation(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Color.Green,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        )
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = uiState.showPAT,
                            onCheckedChange = { viewModel.toggleShowPAT() },
                            colors = CheckboxDefaults.colors(
                                checkedColor = Color.Green
                            )
                        )
                        Text("Show PAT", style = MaterialTheme.typography.bodyMedium)
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Button(
                        onClick = { viewModel.saveGitHubSettings(githubService) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.Green,
                            contentColor = Color.Black
                        )
                    ) {
                        Text("SAVE GITHUB SETTINGS")
                    }

                    if (uiState.saveMessage.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = uiState.saveMessage,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (uiState.saveMessage.contains("saved"))
                                Color.Green
                            else
                                Color.Red
                        )
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Sync Status & Button
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Status Ampel
                            Box(
                                modifier = Modifier
                                    .size(16.dp)
                                    .background(
                                        color = when (uiState.syncStatus) {
                                            SyncStatus.SUCCESS -> Color.Green
                                            SyncStatus.ERROR -> Color.Red
                                            SyncStatus.SYNCING -> Color(0xFFFFA500)
                                            SyncStatus.UNKNOWN -> Color.Gray
                                        },
                                        shape = MaterialTheme.shapes.small
                                    )
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = when (uiState.syncStatus) {
                                    SyncStatus.SUCCESS -> "Connected"
                                    SyncStatus.ERROR -> "Connection failed"
                                    SyncStatus.SYNCING -> "Syncing..."
                                    SyncStatus.UNKNOWN -> "Not synced"
                                },
                                style = MaterialTheme.typography.bodyMedium,
                                color = when (uiState.syncStatus) {
                                    SyncStatus.SUCCESS -> Color.Green
                                    SyncStatus.ERROR -> Color.Red
                                    SyncStatus.SYNCING -> Color(0xFFFFA500)
                                    SyncStatus.UNKNOWN -> Color.Gray
                                }
                            )
                        }

                        Button(
                            onClick = { viewModel.testSync(githubService) },
                            enabled = uiState.syncStatus != SyncStatus.SYNCING,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary,
                                contentColor = Color.Black
                            )
                        ) {
                            Text(
                                if (uiState.syncStatus == SyncStatus.SYNCING)
                                    "SYNCING..."
                                else
                                    "SYNC NOW"
                            )
                        }
                    }

                    if (uiState.syncMessage.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = uiState.syncMessage,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (uiState.syncStatus == SyncStatus.SUCCESS)
                                Color.Green
                            else
                                Color.Red
                        )
                    }
                }
            }

            // Identity Mirror Section
            item {
                SettingsSection(title = "IDENTITY MIRROR") {
                    Text(
                        text = "Intensity Level",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    MirrorIntensity.values().forEach { intensity ->
                        IntensityOption(
                            intensity = intensity,
                            selected = uiState.mirrorIntensity == intensity,
                            onSelect = { viewModel.updateMirrorIntensity(it) }
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "Preset Mode",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    PresetOption(
                        name = "Steel Discipline",
                        description = "Balanced enforcement (Default)",
                        selected = uiState.mirrorPreset == "steel",
                        onSelect = { viewModel.updatePreset("steel") }
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    PresetOption(
                        name = "Classic Brutal",
                        description = "Maximum aggression mode",
                        selected = uiState.mirrorPreset == "brutal",
                        onSelect = { viewModel.updatePreset("brutal") }
                    )
                }
            }

            // Info Section
            item {
                SettingsSection(title = "ABOUT") {
                    InfoRow("Version", "2.1.0 (Ralph Loop)")
                    Spacer(modifier = Modifier.height(8.dp))
                    InfoRow("Build", "Debug")
                    Spacer(modifier = Modifier.height(8.dp))
                    InfoRow("Platform", "Native Android (Kotlin/Compose)")
                }
            }
        }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
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
                text = title,
                style = MaterialTheme.typography.titleLarge,
                color = Color.Green
            )
            Spacer(modifier = Modifier.height(16.dp))
            content()
        }
    }
}

@Composable
private fun IntensityOption(
    intensity: MirrorIntensity,
    selected: Boolean,
    onSelect: (MirrorIntensity) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = if (selected) Color.Green else MaterialTheme.colorScheme.outline,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (selected)
                Color(0xFF1A4D1A)
            else
                MaterialTheme.colorScheme.surfaceVariant
        ),
        onClick = { onSelect(intensity) }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            RadioButton(
                selected = selected,
                onClick = { onSelect(intensity) },
                colors = RadioButtonDefaults.colors(
                    selectedColor = Color.Green,
                    unselectedColor = Color.Gray
                )
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = intensity.name,
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (selected) Color.Green else MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = when (intensity) {
                        MirrorIntensity.OFF -> "No visual feedback"
                        MirrorIntensity.LOW -> "Subtle indicators"
                        MirrorIntensity.MEDIUM -> "Balanced enforcement"
                        MirrorIntensity.HIGH -> "Maximum aggression"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun PresetOption(
    name: String,
    description: String,
    selected: Boolean,
    onSelect: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = if (selected) Color.Green else MaterialTheme.colorScheme.outline,
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (selected)
                Color(0xFF1A4D1A)
            else
                MaterialTheme.colorScheme.surfaceVariant
        ),
        onClick = onSelect
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            RadioButton(
                selected = selected,
                onClick = onSelect,
                colors = RadioButtonDefaults.colors(
                    selectedColor = Color.Green,
                    unselectedColor = Color.Gray
                )
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = name,
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (selected) Color.Green else MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

// ViewModel
class SettingsViewModel : ViewModel() {

    data class UiState(
        val githubUsername: String = "",
        val githubPAT: String = "",
        val showPAT: Boolean = false,
        val mirrorIntensity: MirrorIntensity = MirrorIntensity.MEDIUM,
        val mirrorPreset: String = "steel",
        val saveMessage: String = "",
        val syncStatus: SyncStatus = SyncStatus.UNKNOWN,
        val syncMessage: String = ""
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    fun loadSettings(githubService: GitHubService) {
        viewModelScope.launch {
            val username = githubService.getUsername() ?: ""
            val pat = githubService.getPAT() ?: ""

            _uiState.value = _uiState.value.copy(
                githubUsername = username,
                githubPAT = pat
            )
        }
    }

    fun updateUsername(username: String) {
        _uiState.value = _uiState.value.copy(
            githubUsername = username,
            saveMessage = ""
        )
    }

    fun updatePAT(pat: String) {
        _uiState.value = _uiState.value.copy(
            githubPAT = pat,
            saveMessage = ""
        )
    }

    fun toggleShowPAT() {
        _uiState.value = _uiState.value.copy(
            showPAT = !_uiState.value.showPAT
        )
    }

    fun updateMirrorIntensity(intensity: MirrorIntensity) {
        _uiState.value = _uiState.value.copy(mirrorIntensity = intensity)
    }

    fun updatePreset(preset: String) {
        _uiState.value = _uiState.value.copy(mirrorPreset = preset)
    }

    fun saveGitHubSettings(githubService: GitHubService) {
        viewModelScope.launch {
            val username = _uiState.value.githubUsername
            val pat = _uiState.value.githubPAT

            if (username.isEmpty() || pat.isEmpty()) {
                _uiState.value = _uiState.value.copy(
                    saveMessage = "Username and PAT are required"
                )
                return@launch
            }

            githubService.saveUsername(username)
            githubService.savePAT(pat)

            _uiState.value = _uiState.value.copy(
                saveMessage = "Settings saved successfully",
                syncStatus = SyncStatus.UNKNOWN
            )
        }
    }

    fun testSync(githubService: GitHubService) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                syncStatus = SyncStatus.SYNCING,
                syncMessage = "Testing GitHub connection..."
            )

            try {
                // Test if credentials are set
                val username = githubService.getUsername()
                val pat = githubService.getPAT()

                if (username.isNullOrEmpty() || pat.isNullOrEmpty()) {
                    _uiState.value = _uiState.value.copy(
                        syncStatus = SyncStatus.ERROR,
                        syncMessage = "GitHub credentials not configured"
                    )
                    return@launch
                }

                // Create test audit file
                val testSuccess = githubService.commitAuditFiles(
                    java.time.LocalDate.now(),
                    "Test sync from Ralph-CoS Settings at ${java.time.Instant.now()}"
                )

                if (testSuccess) {
                    _uiState.value = _uiState.value.copy(
                        syncStatus = SyncStatus.SUCCESS,
                        syncMessage = "✓ GitHub connection successful"
                    )
                } else {
                    _uiState.value = _uiState.value.copy(
                        syncStatus = SyncStatus.ERROR,
                        syncMessage = "× Sync failed - check credentials"
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    syncStatus = SyncStatus.ERROR,
                    syncMessage = "× Error: ${e.message}"
                )
            }
        }
    }
}
