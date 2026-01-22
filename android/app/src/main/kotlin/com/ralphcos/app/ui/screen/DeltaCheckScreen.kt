package com.ralphcos.app.ui.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * Delta-Check / Inbox Lock Screen (Feature 10)
 *
 * Locks app access if inbox has >10 items
 * Forces user to process inbox to Inbox Zero
 * Brutal enforcement of GTD principles
 */

data class InboxItem(
    val id: String,
    val title: String,
    val source: String,
    val createdAt: Long,
    val processed: Boolean = false
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeltaCheckScreen(
    onInboxZeroAchieved: () -> Unit = {}
) {
    val viewModel: DeltaCheckViewModel = viewModel()
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadInboxItems()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("INBOX LOCK") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Red,
                    titleContentColor = Color.White
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
            // Lock indicator
            if (uiState.isLocked) {
                LockIndicatorCard(itemCount = uiState.unprocessedCount)
                Spacer(modifier = Modifier.height(24.dp))
            } else {
                InboxZeroCard()
                Spacer(modifier = Modifier.height(24.dp))
                Button(
                    onClick = onInboxZeroAchieved,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.Green,
                        contentColor = Color.Black
                    )
                ) {
                    Text("ZUR APP")
                }
                return@Scaffold
            }

            // Stats
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${uiState.unprocessedCount} / ${uiState.totalCount} Items",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "Ziel: 0",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.Green
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Progress bar
            LinearProgressIndicator(
                progress = (uiState.totalCount - uiState.unprocessedCount) / uiState.totalCount.toFloat(),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                color = Color.Green,
                trackColor = Color.Red,
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Inbox items list
            Text(
                text = "INBOX ITEMS",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(16.dp))

            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                itemsIndexed(
                    items = uiState.items,
                    key = { _, item -> item.id }
                ) { index, item ->
                    InboxItemCard(
                        item = item,
                        index = index + 1,
                        onProcess = {
                            viewModel.processItem(item.id)
                            if (viewModel.uiState.value.unprocessedCount == 0) {
                                onInboxZeroAchieved()
                            }
                        },
                        onDelete = {
                            viewModel.deleteItem(item.id)
                            if (viewModel.uiState.value.unprocessedCount == 0) {
                                onInboxZeroAchieved()
                            }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Quick actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { viewModel.addDemoItems() },
                    modifier = Modifier.weight(1f)
                ) {
                    Text("+ DEMO ITEMS")
                }

                Button(
                    onClick = { viewModel.processAll() },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFFA500),
                        contentColor = Color.Black
                    )
                ) {
                    Text("ALLE PROCESSED")
                }
            }
        }
    }
}

@Composable
private fun LockIndicatorCard(itemCount: Int) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 3.dp,
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
                text = "APP GESPERRT",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.Red,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "$itemCount Items im Inbox",
                style = MaterialTheme.typography.titleLarge,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = """
                    Inbox >10 Items = Chaos.
                    Reduziere auf 0 für Zugriff.

                    Keine Ausreden. Process now.
                """.trimIndent(),
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun InboxZeroCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1A4D1A) // Dark green
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = "Inbox Zero",
                modifier = Modifier.size(64.dp),
                tint = Color.Green
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "INBOX ZERO",
                style = MaterialTheme.typography.headlineMedium,
                color = Color.Green,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Sauber. App entsperrt.",
                style = MaterialTheme.typography.bodyLarge,
                color = Color(0xFF90EE90)
            )
        }
    }
}

@Composable
private fun InboxItemCard(
    item: InboxItem,
    index: Int,
    onProcess: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 2.dp,
                color = if (item.processed) Color.Green else Color(0xFFFFA500),
                shape = MaterialTheme.shapes.medium
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (item.processed)
                Color(0xFF1A4D1A)
            else
                MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "#$index",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (item.processed)
                        Color.Green
                    else
                        MaterialTheme.colorScheme.onSurface,
                    textDecoration = if (item.processed)
                        TextDecoration.LineThrough
                    else
                        null
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = item.source,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }

            if (!item.processed) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    IconButton(
                        onClick = onProcess,
                        colors = IconButtonDefaults.iconButtonColors(
                            contentColor = Color.Green
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "Process"
                        )
                    }

                    IconButton(
                        onClick = onDelete,
                        colors = IconButtonDefaults.iconButtonColors(
                            contentColor = Color.Red
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Delete"
                        )
                    }
                }
            }
        }
    }
}

// ViewModel
class DeltaCheckViewModel : ViewModel() {

    data class UiState(
        val items: List<InboxItem> = emptyList(),
        val totalCount: Int = 0,
        val unprocessedCount: Int = 0,
        val isLocked: Boolean = false
    )

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState

    private val _items = mutableListOf<InboxItem>()

    fun loadInboxItems() {
        viewModelScope.launch {
            // In production, load from persistent storage
            // For demo, use in-memory list
            if (_items.isEmpty()) {
                addDemoItems()
            } else {
                updateState()
            }
        }
    }

    fun addDemoItems() {
        val demoItems = listOf(
            InboxItem("1", "Email von Customer Support", "Gmail", System.currentTimeMillis()),
            InboxItem("2", "Rechnungen prüfen", "Notion", System.currentTimeMillis()),
            InboxItem("3", "Meeting Notes aufräumen", "Obsidian", System.currentTimeMillis()),
            InboxItem("4", "Duolingo Lesson", "App", System.currentTimeMillis()),
            InboxItem("5", "LinkedIn Message bearbeiten", "LinkedIn", System.currentTimeMillis()),
            InboxItem("6", "Code Review Request", "GitHub", System.currentTimeMillis()),
            InboxItem("7", "Blogpost Entwurf fertigstellen", "Draft", System.currentTimeMillis()),
            InboxItem("8", "Termin beim Zahnarzt buchen", "TODO", System.currentTimeMillis()),
            InboxItem("9", "Steuererklärung vorbereiten", "Steuer", System.currentTimeMillis()),
            InboxItem("10", "Workout Plan aktualisieren", "Fitness", System.currentTimeMillis()),
            InboxItem("11", "Onboarding Docs schreiben", "Work", System.currentTimeMillis()),
            InboxItem("12", "Newsletter lesen", "Email", System.currentTimeMillis())
        )

        _items.clear()
        _items.addAll(demoItems)
        updateState()
    }

    fun processItem(id: String) {
        val index = _items.indexOfFirst { it.id == id }
        if (index != -1) {
            _items[index] = _items[index].copy(processed = true)
            updateState()
        }
    }

    fun deleteItem(id: String) {
        _items.removeAll { it.id == id }
        updateState()
    }

    fun processAll() {
        _items.clear()
        updateState()
    }

    private fun updateState() {
        val unprocessed = _items.filter { !it.processed }
        _uiState.value = UiState(
            items = _items.toList(),
            totalCount = _items.size,
            unprocessedCount = unprocessed.size,
            isLocked = unprocessed.size > 10
        )
    }
}
