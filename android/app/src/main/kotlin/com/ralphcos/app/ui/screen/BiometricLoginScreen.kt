package com.ralphcos.app.ui.screen

import android.app.Activity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

@Composable
fun BiometricLoginScreen(
    onAuthSuccess: () -> Unit
) {
    val context = LocalContext.current
    val activity = context as? FragmentActivity

    var authStatus by remember { mutableStateOf("") }
    var biometricAvailable by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        // Check if biometric is available
        val biometricManager = BiometricManager.from(context)
        biometricAvailable = when (biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        )) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    fun showBiometricPrompt() {
        if (activity == null) {
            authStatus = "Error: Activity not available"
            return
        }

        val executor = ContextCompat.getMainExecutor(context)

        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    authStatus = "Authentication successful"
                    onAuthSuccess()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    authStatus = "Authentication error: $errString"
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    authStatus = "Authentication failed"
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Ralph-CoS Login")
            .setSubtitle("Authenticate to access your integrity data")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Lock,
                contentDescription = "Lock",
                modifier = Modifier.size(80.dp),
                tint = Color.Green
            )

            Spacer(modifier = Modifier.height(32.dp))

            Text(
                text = "RALPH-CoS",
                style = MaterialTheme.typography.headlineLarge,
                color = Color.Green
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Executive Integrity OS",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(48.dp))

            Button(
                onClick = { showBiometricPrompt() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = biometricAvailable,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Green,
                    contentColor = Color.Black
                )
            ) {
                Text(
                    text = if (biometricAvailable)
                        "AUTHENTICATE"
                    else
                        "BIOMETRIC NOT AVAILABLE"
                )
            }

            if (authStatus.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = authStatus,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (authStatus.contains("successful"))
                        Color.Green
                    else
                        Color.Red,
                    textAlign = TextAlign.Center
                )
            }

            if (!biometricAvailable) {
                Spacer(modifier = Modifier.height(16.dp))
                TextButton(
                    onClick = onAuthSuccess
                ) {
                    Text("SKIP (Debug Only)")
                }
            }
        }
    }
}
