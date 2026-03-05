// ============================================
// 🎓 APP THEME (app_theme.dart) — Fixed
//
// THE BUG: Material 3 has a "color seeding" system that
// automatically generates a full color palette from your
// primary color. Sometimes this bleeds blue tones into
// buttons and headers even when you set green.
//
// THE FIX: Explicitly set EVERY color in ColorScheme so
// Material 3 has no room to inject its own palette.
// We also define a surfaceTint (used for elevated surfaces)
// as our green so nothing goes blue.
// ============================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZippaColors {
  // Primary brand colors
  static const Color primaryDark    = Color(0xFF1B5E20);
  static const Color primary        = Color(0xFF2E7D32);
  static const Color primaryLight   = Color(0xFF4CAF50);
  static const Color accent         = Color(0xFF66BB6A);

  // Neutrals
  static const Color background     = Color(0xFFF7FAF7);
  static const Color surface        = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary    = Color(0xFF1A1A2E);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textLight      = Color(0xFF9CA3AF);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // Status
  static const Color success        = Color(0xFF10B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFEF4444);
  static const Color info           = Color(0xFF3B82F6);

  // Gradients
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
  static ThemeData get lightTheme {
    // ============================================
    // Build the full ColorScheme manually so Material 3
    // NEVER overrides our green with its auto-seeded palette.
    // Every single slot is set explicitly to green tones.
    // ============================================
    const colorScheme = ColorScheme(
      brightness:           Brightness.light,
      // Primaries
      primary:              ZippaColors.primary,
      onPrimary:            ZippaColors.textOnPrimary,
      primaryContainer:     Color(0xFFC8E6C9),   // light green container
      onPrimaryContainer:   ZippaColors.primaryDark,
      // Secondaries (also green — not blue!)
      secondary:            ZippaColors.primaryLight,
      onSecondary:          ZippaColors.textOnPrimary,
      secondaryContainer:   Color(0xFFDCEEDC),
      onSecondaryContainer: ZippaColors.primaryDark,
      // Tertiary
      tertiary:             ZippaColors.accent,
      onTertiary:           Colors.white,
      tertiaryContainer:    Color(0xFFE8F5E9),
      onTertiaryContainer:  ZippaColors.primaryDark,
      // Error
      error:                ZippaColors.error,
      onError:              Colors.white,
      errorContainer:       Color(0xFFFFDAD6),
      onErrorContainer:     Color(0xFF410002),
      // Surfaces
      surface:              ZippaColors.surface,
      onSurface:            ZippaColors.textPrimary,
      surfaceContainerHighest: Color(0xFFE8F5E9),
      onSurfaceVariant:     ZippaColors.textSecondary,
      // Outline & others
      outline:              Color(0xFFCBD5CB),
      outlineVariant:       Color(0xFFE0EAE0),
      shadow:               Colors.black,
      scrim:                Colors.black,
      inverseSurface:       ZippaColors.primaryDark,
      onInverseSurface:     Colors.white,
      inversePrimary:       ZippaColors.primaryLight,
      // surfaceTint colors the FAB, cards on elevation — must be green!
      surfaceTint:          ZippaColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ZippaColors.background,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: ZippaColors.surface,
        foregroundColor: ZippaColors.textPrimary,
        surfaceTintColor: Colors.transparent, // prevents green tint on scroll
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ZippaColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: ZippaColors.textPrimary),
      ),

      // Text theme
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold,  color: ZippaColors.textPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold,  color: ZippaColors.textPrimary),
        headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: ZippaColors.textPrimary),
        bodyLarge:     GoogleFonts.poppins(fontSize: 16, color: ZippaColors.textPrimary),
        bodyMedium:    GoogleFonts.poppins(fontSize: 14, color: ZippaColors.textSecondary),
        bodySmall:     GoogleFonts.poppins(fontSize: 12, color: ZippaColors.textLight),
        labelLarge:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: ZippaColors.textOnPrimary),
      ),

      // Elevated button — fully green
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZippaColors.primary,
          foregroundColor: ZippaColors.textOnPrimary,
          disabledBackgroundColor: ZippaColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZippaColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: ZippaColors.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text fields
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZippaColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: ZippaColors.textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: ZippaColors.textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.poppins(color: ZippaColors.primary, fontSize: 14),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: ZippaColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ZippaColors.surface,
        selectedItemColor: ZippaColors.primary,
        unselectedItemColor: ZippaColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
      ),

      // FAB — force green
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ZippaColors.primary,
        foregroundColor: Colors.white,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ZippaColors.primary;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ZippaColors.primary,
      ),
    );
  }
}
