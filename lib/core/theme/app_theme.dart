import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final colors = AppColorsExtension.dark;
    
    return baseTheme.copyWith(
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primaryGold,
      cardColor: colors.card,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryGold,
        secondary: colors.softBronze,
        surface: colors.card,
        error: colors.error,
        onPrimary: colors.background,
        onSecondary: colors.textWhite,
        onSurface: colors.textWhite,
      ),
      extensions: [colors],
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.15,
        ),
        titleMedium: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.15,
        ),
        titleSmall: GoogleFonts.outfit(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          color: colors.textWhite,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: colors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          letterSpacing: 0.25,
        ),
        bodySmall: GoogleFonts.inter(
          color: colors.textMuted,
          fontWeight: FontWeight.w400,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
        labelLarge: GoogleFonts.outfit(
          color: colors.background,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 1.25,
        ),
      ),

      // Input Decoration (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        hintStyle: GoogleFonts.inter(
          color: colors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: colors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          color: colors.primaryGold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accentBrown, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accentBrown, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        errorStyle: GoogleFonts.inter(
          color: colors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryGold,
          foregroundColor: colors.background,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          elevation: 2,
          shadowColor: colors.primaryGold.withOpacity(0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryGold,
          side: BorderSide(color: colors.primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.accentBrown, width: 1),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.background,
        selectedItemColor: colors.primaryGold,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    final colors = AppColorsExtension.light;
    
    return baseTheme.copyWith(
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primaryGold,
      cardColor: colors.card,
      colorScheme: ColorScheme.light(
        primary: colors.primaryGold,
        secondary: colors.softBronze,
        surface: colors.card,
        error: colors.error,
        onPrimary: colors.background,
        onSecondary: colors.textWhite,
        onSurface: colors.textWhite,
      ),
      extensions: [colors],
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        displaySmall: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.15,
        ),
        titleMedium: GoogleFonts.outfit(
          color: colors.textWhite,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: 0.15,
        ),
        titleSmall: GoogleFonts.outfit(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          color: colors.textWhite,
          fontWeight: FontWeight.w400,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: colors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
          letterSpacing: 0.25,
        ),
        bodySmall: GoogleFonts.inter(
          color: colors.textMuted,
          fontWeight: FontWeight.w400,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
        labelLarge: GoogleFonts.outfit(
          color: colors.textWhite, // Primary dark text for light theme primary button
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 1.25,
        ),
      ),

      // Input Decoration (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        hintStyle: GoogleFonts.inter(
          color: colors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: colors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          color: colors.primaryGold,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accentBrown, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accentBrown, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        errorStyle: GoogleFonts.inter(
          color: colors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryGold,
          foregroundColor: colors.textWhite, // Dark text on primary gold button
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          elevation: 0,
          shadowColor: Colors.transparent, // No shadow/glow
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.card, // White background
          foregroundColor: colors.primaryGold,
          side: BorderSide(color: colors.accentBrown, width: 1), // Gold border
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0, // No shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.accentBrown, width: 1), // 1px gold border
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.card,
        selectedItemColor: colors.primaryGold,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    );
  }
}
