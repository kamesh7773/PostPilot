import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6D3BF5);
  static const Color secondary = Color(0xFFF43F8E);
  static const Color accent = Color(0xFFB8F15C);
  static const Color primarySoft = Color(0xFFEEE8FF);

  static const Color background = Color(0xFFF6F6FA);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF0F0F6);

  static const Color textPrimary = Color(0xFF111118);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textHint = Color(0xFFA2A2B8);

  static const Color border = Color(0xFFE9E9F1);
  static const Color divider = Color(0xFFE9E9F1);

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFE11D48);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);

  // Dark mode neutrals. Brand colors above are shared by both modes.
  static const Color darkPrimaryText = Color(0xFFA98BFF);
  static const Color darkPrimarySoft = Color(0xFF2A1F4D);
  static const Color darkBackground = Color(0xFF07070C);
  static const Color darkSurface = Color(0xFF17171F);
  static const Color darkSurfaceMuted = Color(0xFF21212C);
  static const Color darkTextPrimary = Color(0xFFF4F4F8);
  static const Color darkTextSecondary = Color(0xFFA3A3B8);
  static const Color darkTextHint = Color(0xFF6E6E84);
  static const Color darkBorder = Color(0xFF2B2B38);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}
