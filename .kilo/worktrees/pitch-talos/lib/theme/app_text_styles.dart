import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Шрифты дизайн-системы: Unbounded — заголовки/дисплей, Manrope — текст, JetBrains Mono — цены.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display({double size = 16, FontWeight weight = FontWeight.w700, Color color = AppColors.text}) =>
      GoogleFonts.unbounded(fontSize: size, fontWeight: weight, color: color, height: 1.3);

  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w600, Color color = AppColors.text}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

  static TextStyle mono({double size = 15, FontWeight weight = FontWeight.w700, Color color = AppColors.text}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);
}
