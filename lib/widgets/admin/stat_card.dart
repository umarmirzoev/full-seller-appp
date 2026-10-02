import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool deltaUp;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value, this.delta, this.deltaUp = true, this.icon = Icons.bar_chart_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700, color: AppColors.text3)),
          Icon(icon, size: 18, color: AppColors.primaryDark),
        ]),
        const SizedBox(height: 14),
        Text(value, style: AppTextStyles.display(size: 24)),
        if (delta != null) ...[
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(deltaUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: deltaUp ? const Color(0xFF15803D) : AppColors.danger),
            const SizedBox(width: 4),
            Text(delta!, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w700, color: deltaUp ? const Color(0xFF15803D) : AppColors.danger)),
          ]),
        ],
      ]),
    );
  }
}
