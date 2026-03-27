import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Glassmorphism container widget
/// Creates a frosted glass effect with customizable blur and opacity
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.blur = 20,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.glassSurface.withValues(alpha: 0.9),
        borderRadius: radius,
        border: border ?? Border(
          top: BorderSide(
            color: AppColors.white.withValues(alpha: 0.04),
            width: 0.5,
          ),
          left: BorderSide(
            color: AppColors.white.withValues(alpha: 0.04),
            width: 0.5,
          ),
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (!enableBlur) {
      return content;
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}

/// Glowing button with gradient background
class GlowButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Gradient gradient;
  final List<BoxShadow>? glowShadows;
  final EdgeInsetsGeometry padding;

  GlowButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    Gradient? gradient,
    this.glowShadows,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  }) : gradient = gradient ?? AppColors.primaryGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: glowShadows ?? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Neon glow text widget for titles
class NeonText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final double glowIntensity;

  const NeonText(
    this.text, {
    super.key,
    this.style,
    this.glowColor = AppColors.primary,
    this.glowIntensity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.headlineMedium)?.copyWith(
        shadows: [
          Shadow(
            color: glowColor.withValues(alpha: glowIntensity),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }
}

/// Ambient glow background decoration
class AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;
  final double opacity;
  final Alignment alignment;

  const AmbientGlow({
    super.key,
    this.color = AppColors.primary,
    this.size = 400,
    this.blur = 120,
    this.opacity = 0.05,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment.y < 0 ? null : (alignment.y > 0 ? null : 0),
      bottom: alignment.y > 0 ? 0 : null,
      left: alignment.x < 0 ? 0 : (alignment.x > 0 ? null : null),
      right: alignment.x > 0 ? 0 : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: blur,
              spreadRadius: size / 2,
            ),
          ],
        ),
      ),
    );
  }
}
