package com.ralphcos.app

import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
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

class MainActivity : FragmentActivity() {

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
        val geminiService = com.ralphcos.app.service.GeminiService(applicationContext)

        // Schedule background workers
        DelayedAuditWorker.schedule(applicationContext)
        PatternInterruptionWorker.scheduleAll(applicationContext)

        setContent {
            RalphTheme {
                var isAuthenticated by remember { mutableStateOf(false) }

                if (isAuthenticated) {
                    RalphApp(
                        vowRepository = vowRepository,
                        integrityRepository = integrityRepository,
                        githubService = githubService,
                        geminiService = geminiService,
                        database = database
                    )
                } else {
                    BiometricLoginScreen(
                        onAuthSuccess = { isAuthenticated = true }
                    )
                }
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
    githubService: GitHubService,
    geminiService: com.ralphcos.app.service.GeminiService,
    database: RalphDatabase
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
                        onNavigateToSettings = { navController.navigate("settings") },
                        onNavigateToRepairMode = { navController.navigate("repair_mode") },
                        onNavigateToChallengeGate = { navController.navigate("challenge_gate") },
                        onNavigateToDeltaCheck = { navController.navigate("delta_check") },
                        onNavigateToSundayRitual = { navController.navigate("sunday_ritual") }
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

                composable("repair_mode") {
                    RepairModeScreen(
                        integrityRepository = integrityRepository,
                        onNavigateBack = {
                            navController.popBackStack()
                        }
                    )
                }

                composable("challenge_gate") {
                    ChallengeGateScreen(
                        integrityRepository = integrityRepository,
                        geminiService = geminiService,
                        challengeDao = database.challengeDao(),
                        onStartChallenge = {
                            navController.popBackStack()
                        },
                        onContinue = {
                            navController.popBackStack()
                        }
                    )
                }

                composable("delta_check") {
                    DeltaCheckScreen(
                        onInboxZeroAchieved = {
                            navController.popBackStack()
                        }
                    )
                }

                composable("sunday_ritual") {
                    SundayRitualScreen(
                        vowRepository = vowRepository,
                        integrityRepository = integrityRepository,
                        githubService = githubService,
                        geminiService = geminiService,
                        onRitualCompleted = {
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
    onNavigateToSettings: () -> Unit,
    onNavigateToRepairMode: () -> Unit = {},
    onNavigateToChallengeGate: () -> Unit = {},
    onNavigateToDeltaCheck: () -> Unit = {},
    onNavigateToSundayRitual: () -> Unit = {}
) {
    // Update currentTime every minute
    var currentTime by remember { mutableStateOf(java.time.LocalTime.now()) }
    LaunchedEffect(Unit) {
        while (true) {
            kotlinx.coroutines.delay(60000) // Update every minute
            currentTime = java.time.LocalTime.now()
        }
    }

    val eveningWindowStart = java.time.LocalTime.of(17, 0)
    val isEveningWindowOpen = currentTime.isAfter(eveningWindowStart) ||
                               currentTime.equals(eveningWindowStart)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
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


        // Sunday Ritual - only visible on Sundays
        val isSunday = java.time.LocalDate.now().dayOfWeek == java.time.DayOfWeek.SUNDAY
        val sundayWindowStart = java.time.LocalTime.of(13, 0)
        val sundayWindowEnd = java.time.LocalTime.of(22, 0)
        val isSundayWindowOpen = isSunday &&
                                  currentTime.isAfter(sundayWindowStart) &&
                                  currentTime.isBefore(sundayWindowEnd)

        if (isSunday) {
            Button(
                onClick = onNavigateToSundayRitual,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(72.dp),
                enabled = isSundayWindowOpen,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isSundayWindowOpen)
                        Color(0xFFFFD700) // Gold
                    else
                        MaterialTheme.colorScheme.surfaceVariant,
                    contentColor = Color.Black,
                    disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                    disabledContentColor = Color.Gray
                )
            ) {
                Text(
                    if (isSundayWindowOpen)
                        "SUNDAY RITUAL"
                    else
                        "SUNDAY RITUAL (Opens at 13:00)"
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        OutlinedButton(
            onClick = onNavigateToRepairMode,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = Color(0xFFFFA500)
            )
        ) {
            Text("REPAIR MODE")
        }

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedButton(
            onClick = onNavigateToDeltaCheck,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = Color.Red
            )
        ) {
            Text("INBOX CHECK")
        }

        Spacer(modifier = Modifier.height(32.dp))

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
