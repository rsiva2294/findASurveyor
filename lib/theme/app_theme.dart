
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  // --- PRIVATE CONSTANTS FOR REUSABILITY ---

  // A more modern and highly legible font pairing.
  // Poppins for headers and titles, Lato for body text.
  static final TextTheme _lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
    displayMedium: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
    titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1A202C)),
    titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
    titleSmall: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
    bodyLarge: GoogleFonts.lato(fontSize: 16, height: 1.5, color: const Color(0xFF2D3748)),
    bodyMedium: GoogleFonts.lato(fontSize: 14, height: 1.5, color: const Color(0xFF4A5568)),
    labelLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
  );

  static final TextTheme _darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
    displayMedium: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
    titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
    titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
    titleSmall: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
    bodyLarge: GoogleFonts.lato(fontSize: 16, height: 1.5, color: Colors.white),
    bodyMedium: GoogleFonts.lato(fontSize: 14, height: 1.5, color: Colors.white70),
    labelLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
  );

  // Defining a static border shape for reusability.
  static final _roundedBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  // --- LIGHT THEME DEFINITION ---

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00796B), // A standard Teal shade
      brightness: Brightness.light,
      primary: const Color(0xFF00796B),
      secondary: const Color(0xFF004D40),
      background: const Color(0xFFF7FAFC),
      surface: Colors.white,
      error: const Color(0xFFD32F2F),
    ),

    textTheme: _lightTextTheme,
    scaffoldBackgroundColor: const Color(0xFFF7FAFC),

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF00796B),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: _lightTextTheme.titleLarge?.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: const Color(0xFF00796B),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A202C),
      ),
      subtitleTextStyle: GoogleFonts.lato(
        fontSize: 12,
        color: const Color(0xFF4A5568),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _lightTextTheme.labelLarge,
        shape: _roundedBorder,
        elevation: 2,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
      ),
      labelStyle: _lightTextTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: _roundedBorder,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.antiAlias,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      labelStyle: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: const StadiumBorder(),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF00796B),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dialogTheme: DialogThemeData(
      shape: _roundedBorder,
      titleTextStyle: _lightTextTheme.titleMedium?.copyWith(color: Colors.black87),
    ),
  );

  // --- DARK THEME DEFINITION ---

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4DB6AC),
      brightness: Brightness.dark,
      primary: const Color(0xFF4DB6AC),
      secondary: const Color(0xFF80CBC4),
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      error: const Color(0xFFCF6679),
    ),

    textTheme: _darkTextTheme,
    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 1,
      titleTextStyle: _darkTextTheme.titleLarge,
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: const Color(0xFF4DB6AC),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      subtitleTextStyle: GoogleFonts.lato(
        fontSize: 12,
        color: Colors.white70,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _darkTextTheme.labelLarge?.copyWith(color: Colors.black),
        shape: _roundedBorder,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
      ),
      labelStyle: _darkTextTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: _roundedBorder,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: const Color(0xFF1E1E1E),
      clipBehavior: Clip.antiAlias,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      labelStyle: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: const StadiumBorder(),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF4DB6AC),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: _roundedBorder,
      titleTextStyle: _darkTextTheme.titleMedium,
    ),
  );
}