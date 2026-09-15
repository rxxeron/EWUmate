import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

import 'ewu_theme_extension.dart';

class AppTheme {
  // Brand Colors (Figma Design Tokens)
  static const Color slate900 = AppColors.primaryNavy; // #071426 App Scaffold Background
  static const Color slate800 = AppColors.surfaceNavyBlue; // #0D2342 Containers & Cards
  static const Color slate400 = AppColors.secondaryText; // #8493A8 Secondary Text/Subtitles
  static const Color cyanAccent = AppColors.primaryCyan; // #19D9F5 Primary Brand Action
  static const Color cyanDark = Color(0xFF0891B2); // Secondary Cyan

  static ThemeData get darkTheme {
    final baseDark = ThemeData.dark();
    return baseDark.copyWith(
      scaffoldBackgroundColor: AppColors.primaryNavy,
      extensions: const [EwuColors.dark],
      
      // Google Fonts Sora typography applied globally
      textTheme: GoogleFonts.soraTextTheme(baseDark.textTheme),
      
      // Align Color Scheme with Figma Navy & Cyan Brand Identity
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCyan,
        secondary: AppColors.secondarySoftBlue,
        surface: AppColors.surfaceNavyBlue,
        onSurface: Colors.white,
        onSurfaceVariant: AppColors.secondaryText,
      ),

      // Global AppBar Configuration
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.sora(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),

      // Global Card Configuration
      cardTheme: CardThemeData(
        color: AppColors.surfaceNavyBlue.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),

      // Global Chip Configuration
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryNavy,
        selectedColor: AppColors.primaryCyan,
        disabledColor: Colors.transparent,
        labelStyle: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
        secondaryLabelStyle: GoogleFonts.sora(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),

      // Global Bottom Sheet Configuration
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceNavyBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Global InputDecoration Configuration for text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceNavyBlue.withValues(alpha: 0.6),
        hintStyle: GoogleFonts.sora(color: AppColors.secondaryText, fontSize: 14),
        prefixIconColor: AppColors.secondaryText,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
      ),

      // Global Text Selection Cursor colors
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryCyan,
        selectionColor: Color(0xFF0284C7),
        selectionHandleColor: AppColors.primaryCyan,
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseLight = ThemeData.light();
    return baseLight.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      extensions: const [EwuColors.light],
      
      textTheme: GoogleFonts.soraTextTheme(baseLight.textTheme),
      
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF2563EB),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF64748B),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: GoogleFonts.sora(
          color: const Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFF0284C7),
        disabledColor: Colors.transparent,
        labelStyle: GoogleFonts.sora(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        secondaryLabelStyle: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Color(0x140F172A), width: 1),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        hintStyle: GoogleFonts.sora(color: const Color(0xFF64748B), fontSize: 14),
        prefixIconColor: const Color(0xFF64748B),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x140F172A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF0284C7),
        selectionColor: Color(0x330284C7),
        selectionHandleColor: Color(0xFF0284C7),
      ),
    );
  }
}
