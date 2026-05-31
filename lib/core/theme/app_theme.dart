import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Slate & Cyan)
  static const Color slate900 = Color(0xFF0F172A); // App Scaffold Background
  static const Color slate800 = Color(0xFF1E293B); // Containers & Cards
  static const Color slate400 = Color(0xFF94A3B8); // Secondary Text/Subtitles
  static const Color cyanAccent = Color(0xFF00E5FF); // Primary Brand Action
  static const Color cyanDark = Color(0xFF0891B2);  // Secondary Cyan

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: slate900,
      
      // Align Color Scheme with Slate & Cyan Brand Identity
      colorScheme: const ColorScheme.dark(
        primary: cyanAccent,
        secondary: cyanDark,
        surface: slate800,
        onSurface: Colors.white,
        onSurfaceVariant: slate400,
      ),

      // Global AppBar Configuration
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),

      // Global Card Configuration
      cardTheme: CardThemeData(
        color: slate800.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),

      // Global Chip Configuration
      chipTheme: ChipThemeData(
        backgroundColor: slate900,
        selectedColor: cyanAccent,
        disabledColor: Colors.transparent,
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        secondaryLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),

      // Global Bottom Sheet Configuration
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: slate800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Global InputDecoration Configuration for text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate800.withValues(alpha: 0.5),
        hintStyle: const TextStyle(color: slate400, fontSize: 14),
        prefixIconColor: slate400,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyanAccent, width: 1.5),
        ),
      ),

      // Global Text Selection Cursor colors
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: cyanAccent,
        selectionColor: Color(0xFF0284C7),
        selectionHandleColor: cyanAccent,
      ),
    );
  }
}
