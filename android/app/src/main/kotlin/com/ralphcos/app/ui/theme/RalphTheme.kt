package com.ralphcos.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Adaptive Brutalism Color Scheme - Dark Mode Only
private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF00FF00),           // Tactical Green
    onPrimary = Color(0xFF000000),
    primaryContainer = Color(0xFF1A1A1A),
    onPrimaryContainer = Color(0xFF00FF00),

    secondary = Color(0xFFFFA500),         // Warning Amber
    onSecondary = Color(0xFF000000),

    tertiary = Color(0xFF991B1B),          // RED Mode
    onTertiary = Color(0xFFFFFFFF),

    background = Color(0xFF0A0A0A),        // Deep Black
    onBackground = Color(0xFFE0E0E0),

    surface = Color(0xFF141414),           // Card Surface
    onSurface = Color(0xFFE0E0E0),
    surfaceVariant = Color(0xFF1F1F1F),
    onSurfaceVariant = Color(0xFF9E9E9E),

    error = Color(0xFFFF0000),             // Hard Red
    onError = Color(0xFF000000),

    outline = Color(0xFF3A3A3A),
    outlineVariant = Color(0xFF262626)
)

@Composable
fun RalphTheme(
    darkTheme: Boolean = true, // Always dark
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}
