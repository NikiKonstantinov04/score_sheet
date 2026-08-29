import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class BridgeScoreApp extends StatelessWidget {
  const BridgeScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorSchemeLight = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32), // тъмнозелено
      brightness: Brightness.light,
    );

    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Bridge Scorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: colorSchemeLight,
        scaffoldBackgroundColor: const Color(0xFFF8F5F0), // топло бяло
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: colorSchemeDark,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}