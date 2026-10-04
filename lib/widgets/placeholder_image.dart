import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Изображение товара/баннера. Если передан [imageUrl] (http/https) — показывает фото из сети,
/// пока оно грузится или если загрузка не удалась — серый плейсхолдер с иконкой.
class PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData icon;
  final String? imageUrl;
  const PlaceholderImage({super.key, this.width, this.height, this.borderRadius, this.icon = Icons.image_outlined, this.imageUrl});

  bool get _hasNetworkImage {
    final url = imageUrl;
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: borderRadius),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.g200, size: (height ?? 80) * 0.32),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasNetworkImage) return _placeholder();
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Фото на сервере большие — декодируем в уменьшенном размере, чтобы не грузить память и не подвешивать UI.
        cacheWidth: 600,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(),
        errorBuilder: (context, error, stack) => _placeholder(),
      ),
    );
  }
}
