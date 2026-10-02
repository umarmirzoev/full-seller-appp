import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LogoMark extends StatelessWidget {
  final bool withText;
  final String text;
  const LogoMark({super.key, this.withText = true, this.text = 'FULL SELLER'});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: AppColors.g500.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text('FS', style: AppTextStyles.display(size: 13, weight: FontWeight.w800, color: Colors.white)),
        ),
        if (withText) ...[
          const SizedBox(width: 9),
          Text(text, style: AppTextStyles.display(size: 16)),
        ],
      ],
    );
  }
}
