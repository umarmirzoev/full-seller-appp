import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int step;
  final int min;
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.step = 1, this.min = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _btn('−', () => onChanged((value - step).clamp(min, 1 << 30))),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          child: Text('$value', style: AppTextStyles.mono(size: 14)),
        ),
        _btn('+', () => onChanged(value + step)),
      ]),
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        color: AppColors.surface2,
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
      ),
    );
  }
}
