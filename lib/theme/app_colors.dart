import 'package:flutter/material.dart';

/// Kinetic Organicism Design System Colors
/// Based on "The Digital Pulse" - bioluminescent, natural green palette
/// Rooted in #7abd4a, a muted "forest floor" green
class AppColors {
  // Primary - Natural Green
  static const Color primary = Color(0xFF94D962);
  static const Color primaryContainer = Color(0xFF7ABD4A);
  static const Color primaryDim = Color(0xFF6BA83D);
  static const Color primaryFixed = Color(0xFF94D962);
  static const Color primaryFixedDim = Color(0xFF7ABD4A);
  static const Color onPrimary = Color(0xFF1A2E0A);
  static const Color onPrimaryFixed = Color(0xFF1A2E0A);
  static const Color onPrimaryContainer = Color(0xFF0F1E06);
  static const Color onPrimaryFixedVariant = Color(0xFF2D4A14);
  static const Color inversePrimary = Color(0xFF4A7A2E);
  static const Color surfaceTint = Color(0xFF94D962);

  // Secondary - Muted Greens (background decorative)
  static const Color secondary = Color(0xFF8BC45A);
  static const Color secondaryDim = Color(0xFF6B9A45);
  static const Color secondaryContainer = Color(0xFF2D4A14);
  static const Color secondaryFixed = Color(0xFF8BC45A);
  static const Color secondaryFixedDim = Color(0xFF7ABD4A);
  static const Color onSecondary = Color(0xFF1A2E0A);
  static const Color onSecondaryFixed = Color(0xFF1A2E0A);
  static const Color onSecondaryContainer = Color(0xFFE8F5DC);
  static const Color onSecondaryFixedVariant = Color(0xFF2D4A14);

  // Tertiary - Accent Green
  static const Color tertiary = Color(0xFFA8E078);
  static const Color tertiaryDim = Color(0xFF7ABD4A);
  static const Color tertiaryContainer = Color(0xFF2D4A14);
  static const Color tertiaryFixed = Color(0xFFA8E078);
  static const Color tertiaryFixedDim = Color(0xFF8BC45A);
  static const Color onTertiary = Color(0xFF1A2E0A);
  static const Color onTertiaryFixed = Color(0xFF1A2E0A);
  static const Color onTertiaryContainer = Color(0xFFE8F5DC);
  static const Color onTertiaryFixedVariant = Color(0xFF2D4A14);

  // Error
  static const Color error = Color(0xFFE57373);
  static const Color errorDim = Color(0xFFC45C5C);
  static const Color errorContainer = Color(0xFF8B3A3A);
  static const Color onError = Color(0xFF2E0A0A);
  static const Color onErrorContainer = Color(0xFFF5DCDC);

  // Surface - Natural Dark Foundation (no pure black)
  static const Color background = Color(0xFF10140F);
  static const Color onBackground = Color(0xFFE8EDE4);
  static const Color surface = Color(0xFF10140F);
  static const Color surfaceDim = Color(0xFF10140F);
  static const Color surfaceBright = Color(0xFF323630);
  static const Color surfaceVariant = Color(0xFF252A22);
  static const Color surfaceContainerLowest = Color(0xFF0C0F0C);
  static const Color surfaceContainerLow = Color(0xFF191D17);
  static const Color surfaceContainer = Color(0xFF1F231C);
  static const Color surfaceContainerHigh = Color(0xFF292E26);
  static const Color surfaceContainerHighest = Color(0xFF323630);
  static const Color onSurface = Color(0xFFE8EDE4);
  static const Color onSurfaceVariant = Color(0xFFB8C4AE);
  static const Color inverseSurface = Color(0xFFE8EDE4);
  static const Color inverseOnSurface = Color(0xFF2D3229);

  // Outline - Ghost Border at 15% opacity for accessibility
  static const Color outline = Color(0xFF8A9580);
  static const Color outlineVariant = Color(0xFF5C6554);

  // Additional UI Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF10140F);

  // Gradient: primary to primary-container at 135°
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, primaryContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get errorGradient => const LinearGradient(
        colors: [errorDim, errorContainer],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Glassmorphism: surface-variant at 60% opacity
  static Color get glassSurface => surfaceVariant.withOpacity(0.6);
  static Color get glassBorder => outlineVariant.withOpacity(0.15);

  // Ambient glow: primary at 8% opacity
  static Color get ambientGlow => primary.withOpacity(0.08);
}
