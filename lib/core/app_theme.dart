import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.deepOrange;
  static final Color primaryDark = Colors.deepOrange.shade900;
  static final Color primaryLight = Colors.deepOrange.shade300;
  
  static const Color backgroundColor = Colors.black;
  static final Color cardColor = Colors.grey.shade900;

  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: cardColor,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: cardColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        fontSize: 20,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 8,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ),
  );
}
