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
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [BoxShadow(color: AppColors.g500.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Image.asset('assets/logo/fs_logo.png', fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
        if (withText) ...[
          const SizedBox(width: 9),
          Text(text, style: AppTextStyles.display(size: 16)),
        ],
      ],
    );
  }
}
