import 'package:flutter/material.dart';

ThemeData buildDarkTheme() {
  const primaryRed = Color(0xFFE50914); // Netflix-like red
  const background = Colors.black;
  const surface = Color(0xFF141414);

  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: primaryRed,
      secondary: primaryRed,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0D0D0D),
      selectedItemColor: primaryRed,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      bodyLarge: const TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    dividerColor: Colors.white12,
    cardColor: surface,
  );
}
