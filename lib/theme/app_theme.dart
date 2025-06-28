
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Common text styles to reuse
  static final _lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(fontSize: 72, fontWeight: FontWeight.bold),
    titleLarge: GoogleFonts.oswald(fontSize: 30, fontStyle: FontStyle.italic),
    bodyMedium: GoogleFonts.merriweather(fontSize: 16, height: 1.5),
    titleMedium: GoogleFonts.oswald(fontSize: 18),
  );

  static final _darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
    titleLarge: GoogleFonts.oswald(fontSize: 30, fontStyle: FontStyle.italic, color: Colors.white),
    bodyMedium: GoogleFonts.merriweather(fontSize: 16, height: 1.5, color: Colors.white),
    titleMedium: GoogleFonts.oswald(fontSize: 18, color: Colors.white),
  );


  // LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    textTheme: _lightTextTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      labelStyle: GoogleFonts.roboto(color: Colors.grey[700]),
      hintStyle: GoogleFonts.roboto(color: Colors.grey[400]),
    ),

    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),

    // NEW WIDGET THEMES FOR LIGHT MODE
    tabBarTheme: TabBarThemeData(
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.roboto(),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      elevation: 8,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: _lightTextTheme.titleMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.teal,
      labelStyle: GoogleFonts.roboto(color: Colors.black87),
      secondaryLabelStyle: GoogleFonts.roboto(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const StadiumBorder(),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.teal,
      thumbColor: Colors.teal,
      inactiveTrackColor: Colors.teal.withAlpha(100),
    ),
  );


  // DARK THEME
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal.shade200,
      brightness: Brightness.dark,
    ),
    textTheme: _darkTextTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade200,
        foregroundColor: Colors.grey[900],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.teal.shade200, width: 2),
      ),
      labelStyle: GoogleFonts.roboto(color: Colors.grey[400]),
      hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
    ),

    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
      color: Colors.grey[850],
    ),

    // NEW WIDGET THEMES FOR DARK MODE
    tabBarTheme: TabBarThemeData(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.teal.shade200, width: 2),
      ),
      labelColor: Colors.teal.shade200,
      unselectedLabelColor: Colors.grey[400],
      labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.roboto(),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.teal.shade200,
      unselectedItemColor: Colors.grey[600],
      elevation: 8,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.teal.shade200,
      foregroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: _darkTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[700],
      selectedColor: Colors.teal.shade200,
      labelStyle: GoogleFonts.roboto(color: Colors.white70),
      secondaryLabelStyle: GoogleFonts.roboto(color: Colors.black87),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const StadiumBorder(),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.teal.shade200,
      thumbColor: Colors.teal.shade200,
      inactiveTrackColor: Colors.teal.shade200.withAlpha(100),
    ),
  );
}