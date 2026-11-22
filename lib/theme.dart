import 'package:material_ui/material_ui.dart';

/// ডিজাইনের নীল রঙগুলো।
class HpsColors {
  static const navy = Color(0xFF0A2F7A);
  static const primary = Color(0xFF0D47A1);
  static const blue = Color(0xFF1565C0);
  static const light = Color(0xFF1E88E5);
  static const sky = Color(0xFFE8F0FE);
  static const surface = Color(0xFFF4F7FC);
  static const important = Color(0xFFE53935);
  static const warning = Color(0xFFF9A825);
  static const success = Color(0xFF2E7D32);

  /// হেডার ও স্প্ল্যাশের গ্রেডিয়েন্ট।
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, primary, light],
  );

  static const buttonGradient = LinearGradient(colors: [primary, light]);

  /// চ্যাট অ্যাভাটারের রঙ (ডিজাইনের মতো)।
  static const avatarColors = [
    Color(0xFF1565C0),
    Color(0xFF7C4DFF),
    Color(0xFFFF8F00),
    Color(0xFF43A047),
    Color(0xFFEC407A),
  ];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HpsColors.primary,
    primary: HpsColors.primary,
    surface: Colors.white,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: HpsColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: HpsColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HpsColors.primary,
        minimumSize: const Size.fromHeight(50),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCFD8E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCFD8E3)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: HpsColors.light,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: HpsColors.sky,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: s.contains(WidgetState.selected)
              ? HpsColors.primary
              : Colors.black87,
        ),
      ),
    ),
  );
}
