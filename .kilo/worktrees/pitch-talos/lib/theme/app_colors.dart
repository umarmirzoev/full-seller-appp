import 'package:flutter/material.dart';

/// Цветовые токены дизайн-системы FULL SELLER (см. common.py --g-* переменные).
class AppColors {
  AppColors._();

  static const g50 = Color(0xFFFFF4EA);
  static const g100 = Color(0xFFFFE1C7);
  static const g200 = Color(0xFFFFC28F);
  static const g400 = Color(0xFFFF8A3D);
  static const g500 = Color(0xFFFF6A00);
  static const g600 = Color(0xFFE85D00);
  static const g700 = Color(0xFFC2410C);
  static const g900 = Color(0xFF4A1D02);

  static const bg = Color(0xFFFFFBF8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFFF4EA);
  static const surface3 = Color(0xFFFFE8D3);

  static const text = Color(0xFF1A1410);
  static const text2 = Color(0xFF6B5F53);
  static const text3 = Color(0xFF9C8F80);

  static const border = Color(0xFFF2E1CE);
  static const borderSoft = Color(0xFFFAEEE0);

  static const primary = g500;
  static const primaryDark = g700;
  static const primaryLight = g400;
  static const onPrimary = Colors.white;

  static const star = Color(0xFFFFB020);
  static const danger = Color(0xFFDC2626);

  static const badgeNew = Color(0xFF2563EB);
  static const badgeSale = danger;

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB15C), g500, Color(0xFFFF3D00)],
    stops: [0.0, 0.55, 1.0],
  );

  static const shadowColor = Color(0x1F4A1D02);
}
