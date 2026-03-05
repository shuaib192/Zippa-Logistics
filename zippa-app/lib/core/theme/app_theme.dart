// ============================================
// 🎓 APP THEME (app_theme.dart)
//
// WHAT IS A THEME?
// A theme is a central place that defines how your entire
// app looks — colors, fonts, button styles, etc.
// Instead of setting colors on each widget individually,
// you define them ONCE here and everything follows.
//
// BRAND COLORS (from Zippa logo):
// - Dark Green (#1B5E20) — Primary brand color
// - Bright Green (#4CAF50) — Accent/highlight color
// - White (#FFFFFF) — Clean backgrounds
// - Dark text for readability
//
// WHY USE A THEME?
// 1. Consistency — every screen looks the same
// 2. Easy to change — update one value, entire app changes
// 3. Professional — no random colors scattered around
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Our brand colors as constants so we can use them anywhere
class ZippaColors {
  // Primary brand colors (from logo)
  static const Color primaryDark = Color(0xFF1B5E20);   // Dark green
  static const Color primary = Color(0xFF2E7D32);        // Medium green
  static const Color primaryLight = Color(0xFF4CAF50);   // Bright green
  static const Color accent = Color(0xFF66BB6A);         // Light accent green
  
  // Neutrals
  static const Color background = Color(0xFFF8FAF8);    // Slight green tint
  static const Color surface = Color(0xFFFFFFFF);        // Pure white
  static const Color cardBg = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);   // Almost black
  static const Color textSecondary = Color(0xFF6B7280);  // Gray
  static const Color textLight = Color(0xFF9CA3AF);      // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White text on green
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient for cards and buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ZippaTheme {
  // ============================================
  // The main theme data object
  // ThemeData is Flutter's class that holds ALL visual settings
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,  // Use the latest Material Design 3
      
      // Color scheme — Flutter uses this to automatically style widgets
      colorScheme: ColorScheme.light(
        primary: ZippaColors.primary,
        onPrimary: ZippaColors.textOnPrimary,
        secondary: ZippaColors.primaryLight,
        surface: ZippaColors.surface,
        error: ZippaColors.error,
      ),
      
      // Background color for all screens
      scaffoldBackgroundColor: ZippaColors.background,
      
      // App bar (top bar) styling
      appBarTheme: AppBarTheme(
        backgroundColor: ZippaColors.surface,
        foregroundColor: ZippaColors.textPrimary,
        elevation: 0,  // No shadow — modern flat design
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ZippaColors.textPrimary,
        ),
      ),
      
      // Default text styles using Poppins font
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        // Headlines
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ZippaColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ZippaColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ZippaColors.textPrimary,
        ),
        // Body text
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: ZippaColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: ZippaColors.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: ZippaColors.textLight,
        ),
        // Labels (for buttons, tabs)
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ZippaColors.textOnPrimary,
        ),
      ),
      
      // Elevated button styling (main action buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZippaColors.primary,
          foregroundColor: ZippaColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 56), // Full width, 56px tall
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button styling (secondary actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZippaColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: ZippaColors.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text field (input box) styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZippaColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZippaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZippaColors.error),
        ),
        hintStyle: GoogleFonts.poppins(
          color: ZippaColors.textLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: ZippaColors.textSecondary,
          fontSize: 14,
        ),
      ),
      
      // Card styling
      cardTheme: CardThemeData(
        color: ZippaColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      
      // Bottom navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ZippaColors.surface,
        selectedItemColor: ZippaColors.primary,
        unselectedItemColor: ZippaColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}
