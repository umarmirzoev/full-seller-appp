import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BadgeRow extends StatelessWidget {
  final List<String> labels;
  const BadgeRow({super.key, required this.labels});

  Color _colorFor(String label) => switch (label) {
        'Новинка' => AppColors.badgeNew,
        'Скидка' => AppColors.badgeSale,
        _ => AppColors.g600,
      };

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: labels
          .map((l) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _colorFor(l), borderRadius: BorderRadius.circular(6)),
                child: Text(l, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
              ))
          .toList(),
    );
  }
}
