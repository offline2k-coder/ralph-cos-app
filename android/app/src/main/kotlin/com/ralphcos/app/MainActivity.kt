package com.ralphcos.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.ralphcos.app.data.RalphDatabase
import com.ralphcos.app.data.repository.IntegrityRepository
import com.ralphcos.app.data.repository.VowRepository
import com.ralphcos.app.service.GitHubService
import com.ralphcos.app.ui.component.IdentityMirror
import com.ralphcos.app.ui.screen.*
import com.ralphcos.app.ui.theme.RalphTheme
import com.ralphcos.app.worker.DelayedAuditWorker
import com.ralphcos.app.worker.PatternInterruptionWorker

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize database
        val database = RalphDatabase.getInstance(applicationContext)

        // Initialize repositories
        val vowRepository = VowRepository(
            database.dailyVowDao(),
            database.eveningClaimDao()
        )
        val integrityRepository = IntegrityRepository(
            database.breachDao(),
            database.integrityScoreDao(),
            database.streakStateDao()
        )
        val githubService = GitHubService(applicationContext)

        // Schedule background workers
        DelayedAuditWorker.schedule(applicationContext)
        PatternInterruptionWorker.scheduleAll(applicationContext)

        setContent {
            RalphTheme {
                RalphApp(
                    vowRepository = vowRepository,
                    integrityRepository = integrityRepository,
                    githubService = githubService
                )
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Clean up if needed
    }
}

@Composable
fun RalphApp(
    vowRepository: VowRepository,
    integrityRepository: IntegrityRepository,
    githubService: GitHubService
) {
    val navController = rememberNavController()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Pinned Identity Mirror at top
            IdentityMirror(
                integrityRepository = integrityRepository,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            // Navigation
            NavHost(
                navController = navController,
                startDestination = "dashboard"
            ) {
                composable("dashboard") {
                    DashboardScreen(
                        onNavigateToMorningVow = { navController.navigate("morning_vow") },
                        onNavigateToEveningRitual = { navController.navigate("evening_ritual") },
                        onNavigateToSettings = { navController.navigate("settings") }
                    )
                }

                composable("morning_vow") {
                    MorningVowScreen(
                        vowRepository = vowRepository,
                        onVowCompleted = {
                            navController.popBackStack()
                        }
                    )
                }

                composable("evening_ritual") {
                    EveningRitualScreen(
                        vowRepository = vowRepository,
                        githubService = githubService,
                        onRitualCompleted = {
                            navController.popBackStack()
                        }
                    )
                }

                composable("settings") {
                    SettingsScreen(
                        githubService = githubService,
                        onNavigateBack = {
                            navController.popBackStack()
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun DashboardScreen(
    onNavigateToMorningVow: () -> Unit,
    onNavigateToEveningRitual: () -> Unit,
    onNavigateToSettings: () -> Unit
) {
    val currentTime = remember { mutableStateOf(java.time.LocalTime.now()) }
    val eveningWindowStart = java.time.LocalTime.of(17, 0)
    val isEveningWindowOpen = currentTime.value.isAfter(eveningWindowStart) ||
                               currentTime.value.equals(eveningWindowStart)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "RALPH-CoS",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.primary
        )

        Text(
            text = "Executive Integrity OS",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = onNavigateToMorningVow,
            modifier = Modifier
                .fillMaxWidth()
                .height(72.dp)
        ) {
            Text("MORNING VOW")
        }

        Button(
            onClick = onNavigateToEveningRitual,
            modifier = Modifier
                .fillMaxWidth()
                .height(72.dp),
            enabled = isEveningWindowOpen,
            colors = ButtonDefaults.buttonColors(
                containerColor = if (isEveningWindowOpen)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.surfaceVariant,
                disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Text(
                if (isEveningWindowOpen)
                    "EVENING RITUAL"
                else
                    "EVENING RITUAL (Opens at 17:00)"
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        OutlinedButton(
            onClick = onNavigateToSettings,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Text("SETTINGS")
        }
    }
}
