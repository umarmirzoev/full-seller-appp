import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const StarRating({super.key, required this.rating, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(Icons.star_rounded, size: size, color: i < filled ? AppColors.star : AppColors.border)),
    );
  }
}
