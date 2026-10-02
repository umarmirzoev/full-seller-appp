import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Плейсхолдер изображения товара/баннера — в реальном приложении заменится на Image.network(imageUrl).
class PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData icon;
  const PlaceholderImage({super.key, this.width, this.height, this.borderRadius, this.icon = Icons.image_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: borderRadius),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.g200, size: (height ?? 80) * 0.32),
    );
  }
}
