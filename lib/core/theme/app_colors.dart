import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  // Primary Palette
  final Color background;
  final Color card;
  final Color primaryGold;
  final Color softBronze;
  final Color accentBrown;
  
  // Neutral Text & Greys
  final Color textWhite;
  final Color textSecondary;
  final Color textMuted;
  
  // Feedback
  final Color error;
  final Color success;

  const AppColorsExtension({
    required this.background,
    required this.card,
    required this.primaryGold,
    required this.softBronze,
    required this.accentBrown,
    required this.textWhite,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.success,
  });

  // Dark Theme (Midnight Gold -> Midnight Purple)
  static const dark = AppColorsExtension(
    background: Color(0xFF0B0914),
    card: Color(0xFF151221),
    primaryGold: Color(0xFF7B61FF),
    softBronze: Color(0xFF6CA8FF),
    accentBrown: Color(0xFF2D2544),
    textWhite: Color(0xFFF8F8F8),
    textSecondary: Color(0xFFC7BCE6),
    textMuted: Color(0xFF8376A5),
    error: Color(0xFFE57373),
    success: Color(0xFF81C784),
  );

  // Light Theme (Ivory Gold -> Light Lavender)
  static const light = AppColorsExtension(
    background: Color(0xFFF5F3FF),
    card: Color(0xFFFFFFFF),
    primaryGold: Color(0xFF7B61FF),
    softBronze: Color(0xFF6CA8FF), 
    accentBrown: Color(0xFFE5E7EB),
    textWhite: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF), 
    error: Color(0xFFEF4444),
    success: Color(0xFF16A34A),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? card,
    Color? primaryGold,
    Color? softBronze,
    Color? accentBrown,
    Color? textWhite,
    Color? textSecondary,
    Color? textMuted,
    Color? error,
    Color? success,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      card: card ?? this.card,
      primaryGold: primaryGold ?? this.primaryGold,
      softBronze: softBronze ?? this.softBronze,
      accentBrown: accentBrown ?? this.accentBrown,
      textWhite: textWhite ?? this.textWhite,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      primaryGold: Color.lerp(primaryGold, other.primaryGold, t)!,
      softBronze: Color.lerp(softBronze, other.softBronze, t)!,
      accentBrown: Color.lerp(accentBrown, other.accentBrown, t)!,
      textWhite: Color.lerp(textWhite, other.textWhite, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

// Global gradient helpers that adapt using an extension method
extension AppColorsExtensionHelper on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.dark;

  LinearGradient get goldGradient => LinearGradient(
    colors: [
      colors.primaryGold,
      colors.primaryGold,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get darkCardGradient => LinearGradient(
    colors: [
      colors.card,
      colors.card,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get luxuryBackgroundGradient => LinearGradient(
    colors: [
      colors.background,
      colors.background,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  LinearGradient get glassBorderGradient => LinearGradient(
    colors: [
      colors.accentBrown,
      colors.accentBrown,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
