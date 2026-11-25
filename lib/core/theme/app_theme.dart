import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1a1a2e);
  static const Color red = Color(0xFFe53935);
  static const Color blue = Color(0xFF1e88e5);
  static const Color green = Color(0xFF43a047);
  static const Color orange = Color(0xFFfb8c00);
  static const Color dark = Color(0xFF16213e);
  static const Color surface = Color(0xFF0f3460);
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1e1e2e);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9e9e9e);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: red,
      secondary: blue,
      surface: card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: red,
        foregroundColor: textLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red, width: 2),
      ),
      labelStyle: const TextStyle(color: textGrey),
      prefixIconColor: textGrey,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primary,
      selectedItemColor: red,
      unselectedItemColor: textGrey,
      type: BottomNavigationBarType.fixed,
    ),
  );
}