import 'package:material_ui/material_ui.dart';

/// স্কুলের রঙ: গাঢ় সবুজ।
const Color hpsGreen = Color(0xFF0B6E4F);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: hpsGreen);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
