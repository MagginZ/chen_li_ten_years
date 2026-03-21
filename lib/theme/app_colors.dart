import 'package:flutter/material.dart';

/// Neon Pulse Design System Colors
/// Based on the "Deep Space" foundation with hyper-vibrant neon accents
class AppColors {
  // Primary - Neon Pink
  static const Color primary = Color(0xFFFF89AB);
  static const Color primaryDim = Color(0xFFE30071);
  static const Color primaryContainer = Color(0xFFFF709E);
  static const Color primaryFixed = Color(0xFFFF709E);
  static const Color primaryFixedDim = Color(0xFFFF5290);
  static const Color onPrimary = Color(0xFF62002D);
  static const Color onPrimaryFixed = Color(0xFF000000);
  static const Color onPrimaryContainer = Color(0xFF4C0021);
  static const Color onPrimaryFixedVariant = Color(0xFF5D002A);
  static const Color inversePrimary = Color(0xFFBC005C);
  static const Color surfaceTint = Color(0xFFFF89AB);

  // Secondary - Neon Cyan
  static const Color secondary = Color(0xFF00E3FD);
  static const Color secondaryDim = Color(0xFF00D4EC);
  static const Color secondaryContainer = Color(0xFF006875);
  static const Color secondaryFixed = Color(0xFF26E6FF);
  static const Color secondaryFixedDim = Color(0xFF00D7F0);
  static const Color onSecondary = Color(0xFF004D57);
  static const Color onSecondaryFixed = Color(0xFF003A42);
  static const Color onSecondaryContainer = Color(0xFFE8FBFF);
  static const Color onSecondaryFixedVariant = Color(0xFF005964);

  // Tertiary - Neon Purple
  static const Color tertiary = Color(0xFFAC89FF);
  static const Color tertiaryDim = Color(0xFF874CFF);
  static const Color tertiaryContainer = Color(0xFF7000FF);
  static const Color tertiaryFixed = Color(0xFFBDA1FF);
  static const Color tertiaryFixedDim = Color(0xFFB190FF);
  static const Color onTertiary = Color(0xFF290067);
  static const Color onTertiaryFixed = Color(0xFF1F0052);
  static const Color onTertiaryContainer = Color(0xFFF8F1FF);
  static const Color onTertiaryFixedVariant = Color(0xFF4700A7);

  // Error
  static const Color error = Color(0xFFFF6E84);
  static const Color errorDim = Color(0xFFD73357);
  static const Color errorContainer = Color(0xFFA70138);
  static const Color onError = Color(0xFF490013);
  static const Color onErrorContainer = Color(0xFFFFB2B9);

  // Surface - Deep Space Foundation
  static const Color background = Color(0xFF0E0E13);
  /// Music Sync 页面背景色
  static const Color musicBackground = Color(0xFF10140F);
  /// Music Sync 进度条滑块发光色 (primary #0xFFFF6E84)
  static const Color musicPrimary = Color(0xFFFF6E84);
  static const Color onBackground = Color(0xFFF8F5FD);
  static const Color surface = Color(0xFF0E0E13);
  static const Color surfaceDim = Color(0xFF0E0E13);
  static const Color surfaceBright = Color(0xFF2C2B33);
  static const Color surfaceVariant = Color(0xFF25252C);
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFF131318);
  static const Color surfaceContainer = Color(0xFF19191F);
  static const Color surfaceContainerHigh = Color(0xFF1F1F26);
  static const Color surfaceContainerHighest = Color(0xFF25252C);
  static const Color onSurface = Color(0xFFF8F5FD);
  static const Color onSurfaceVariant = Color(0xFFACAAB1);
  static const Color inverseSurface = Color(0xFFFBF8FF);
  static const Color inverseOnSurface = Color(0xFF55545A);

  // Outline
  static const Color outline = Color(0xFF76747B);
  static const Color outlineVariant = Color(0xFF48474D);

  // Additional UI Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gradient colors for buttons
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

  // Glassmorphism colors
  static Color get glassSurface => surfaceContainerHigh.withOpacity(0.4);
  static Color get glassBorder => white.withOpacity(0.05);
}
