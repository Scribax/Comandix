import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F172A);
  static const Color backgroundSecondary = Color(0xFF1E293B);
  static const Color backgroundCard = Color(0xFF1E293B);
  
  // Accents
  static const Color accent = Color(0xFF00F0FF); // Electric Blue
  static const Color accentVariant = Color(0xFF3B82F6);
  
  // Status
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444);
  
  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  
  // Glassmorphism
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBackground = Color(0x1AFFFFFF);
}

class GlassmorphicTheme extends ThemeExtension<GlassmorphicTheme> {
  final double blur;
  final double opacity;
  final Color borderColor;
  final BorderRadius borderRadius;

  GlassmorphicTheme({
    required this.blur,
    required this.opacity,
    required this.borderColor,
    required this.borderRadius,
  });

  @override
  GlassmorphicTheme copyWith({
    double? blur,
    double? opacity,
    Color? borderColor,
    BorderRadius? borderRadius,
  }) {
    return GlassmorphicTheme(
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  GlassmorphicTheme lerp(ThemeExtension<GlassmorphicTheme>? other, double t) {
    if (other is! GlassmorphicTheme) return this;
    return GlassmorphicTheme(
      blur: lerpDouble(blur, other.blur, t) ?? blur,
      opacity: lerpDouble(opacity, other.opacity, t) ?? opacity,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t) ?? borderRadius,
    );
  }

  static double? lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0;
    b ??= 0;
    return a + (b - a) * t;
  }
}
