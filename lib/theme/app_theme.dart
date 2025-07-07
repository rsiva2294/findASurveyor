import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- A dedicated class for your app's color palette ---
class _AppColors {
  // --- Primary Colors ---
  static const Color primary = Color(0xFF00796B); // Classic Teal
  static const Color primaryDark = Color(0xFF4DB6AC); // Lighter Teal for dark mode

  // --- Neutral Colors ---
  static const Color textLight = Color(0xFF1A202C); // Dark text for light backgrounds
  static const Color textDark = Color(0xFFF7FAFC); // Light text for dark backgrounds
  static const Color textSubtleLight = Color(0xFF4A5568);
  static const Color textSubtleDark = Color(0xFFA0AEC0);

  // --- Background Colors ---
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color backgroundDark = Color(0xFF1A202C);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF2D3748);

  // --- Accent Colors ---
  static const Color accent = Color(0xFFD69E2E); // Gold/Amber
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);
}

/// A centralized theme class for the application.
/// Provides a consistent, reusable theme for both light and dark modes.
class AppTheme {
  // --- PRIVATE CONSTANTS FOR REUSABILITY ---

  // Shared rounded border for buttons, cards, SnackBars, etc.
  static final _roundedBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

// Shared text themes for light and dark modes
  static final TextTheme _lightTextTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: _AppColors.textLight,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: _AppColors.textLight,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: _AppColors.textLight,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _AppColors.textLight,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _AppColors.textLight,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Lato',
      fontSize: 16,
      height: 1.5,
      color: _AppColors.textSubtleLight,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Lato',
      fontSize: 14,
      height: 1.5,
      color: _AppColors.textSubtleLight,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Lato',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: _AppColors.textLight,
    ),
  );

  static final TextTheme _darkTextTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: _AppColors.textDark,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: _AppColors.textDark,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: _AppColors.textDark,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: _AppColors.textDark,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _AppColors.textDark,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Lato',
      fontSize: 16,
      height: 1.5,
      color: _AppColors.textSubtleDark,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Lato',
      fontSize: 14,
      height: 1.5,
      color: _AppColors.textSubtleDark,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Lato',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: _AppColors.textDark,
    ),
  );

  // --- LIGHT THEME DEFINITION ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _AppColors.primary,
      secondary: _AppColors.accent,
      surface: _AppColors.surfaceLight,
      error: _AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: _AppColors.textLight,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _AppColors.backgroundLight,
    textTheme: _lightTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: _lightTextTheme.titleLarge?.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 3),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: _roundedBorder,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      color: _AppColors.surfaceLight,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _lightTextTheme.labelLarge,
        shape: _roundedBorder,
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _lightTextTheme.labelLarge,
        shape: _roundedBorder,
        side: const BorderSide(color: _AppColors.primary, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _AppColors.primary,
        textStyle: _lightTextTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.primary, width: 2),
      ),
      labelStyle: _lightTextTheme.bodyMedium,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: _lightTextTheme.bodyMedium, // Changed from bodySmall for consistency
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: _AppColors.primary,
      titleTextStyle: _lightTextTheme.titleSmall,
      subtitleTextStyle: _lightTextTheme.bodyMedium,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _AppColors.primary.withOpacity(0.1),
      labelStyle: _lightTextTheme.bodyMedium?.copyWith(
        color: _AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
    dialogTheme: DialogThemeData(
      shape: _roundedBorder,
      backgroundColor: _AppColors.surfaceLight,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16.0),
      shape: _roundedBorder,
      backgroundColor: _AppColors.primary,
      contentTextStyle: _lightTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      actionTextColor: _AppColors.accent,
      disabledActionTextColor: _AppColors.textSubtleLight,
      elevation: 6.0,
      showCloseIcon: true,
      closeIconColor: Colors.white,
    ),
  );

  // --- DARK THEME DEFINITION ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _AppColors.primaryDark,
      secondary: _AppColors.accent,
      surface: _AppColors.surfaceDark,
      error: _AppColors.error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _AppColors.textDark,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: _AppColors.backgroundDark,
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _AppColors.surfaceDark,
      foregroundColor: Colors.white,
      elevation: 1,
      titleTextStyle: _darkTextTheme.titleLarge?.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: _AppColors.primaryDark, width: 3),
      ),
      labelColor: _AppColors.primaryDark,
      unselectedLabelColor: _AppColors.textSubtleDark,
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: _roundedBorder,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      color: _AppColors.surfaceDark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primaryDark,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _darkTextTheme.labelLarge,
        shape: _roundedBorder,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _darkTextTheme.labelLarge,
        shape: _roundedBorder,
        side: const BorderSide(color: _AppColors.primaryDark, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _AppColors.primaryDark,
        textStyle: _darkTextTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.primaryDark, width: 2),
      ),
      labelStyle: _darkTextTheme.bodyMedium,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: _darkTextTheme.bodyMedium, // Changed from bodySmall
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: _AppColors.primaryDark,
      titleTextStyle: _darkTextTheme.titleSmall,
      subtitleTextStyle: _darkTextTheme.bodyMedium,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _AppColors.primaryDark.withOpacity(0.15),
      labelStyle: _darkTextTheme.bodyMedium?.copyWith(
        color: _AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _AppColors.surfaceDark,
      shape: _roundedBorder,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16.0),
      shape: _roundedBorder,
      backgroundColor: _AppColors.primaryDark,
      contentTextStyle: _darkTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      actionTextColor: _AppColors.accent,
      disabledActionTextColor: _AppColors.textSubtleDark,
      elevation: 6.0,
      showCloseIcon: true,
      closeIconColor: Colors.white,
    ),
  );
}