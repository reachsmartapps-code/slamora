import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1B3565);
  static const Color primaryDark = Color(0xFF10264F);
  static const Color accent = Color(0xFFFFB08A);
  static const Color coral = Color(0xFFFF684D);
  static const Color coralDark = Color(0xFFE64F38);
  static const Color coralDeep = Color(0xFFD9432E);
  static const Color peach = Color(0xFFFFD9C7);

  static const Color background = Color(0xFFFFFAF3);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color surfaceWarm = Color(0xFFFFF3E7);
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFCF8),
      Color(0xFFFFFAEB),
      Color(0xFFFBE0D4)],
    stops: [0.0, 0.55, 1.0],
  );

  static const Color textPrimary = Color(0xFF19111F);
  static const Color textSecondary = Color(0xFF667085);

  static const Color border = Color(0xFFF0D7C5);
  static const Color divider = Color(0xFFEFE4D8);
  static const Color shadow = Color(0x1F7A563C);
  static const Color mutedDot = Color(0xFFE1D8CF);

  static const Color success = Color(0xFF4D9A6A);
  static const Color error = Color(0xFFD65C5C);
  static const Color white = Color(0xFFFFFFFF);
}
