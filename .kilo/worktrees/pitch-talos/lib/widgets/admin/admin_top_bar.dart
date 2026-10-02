import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AdminTopBar extends StatelessWidget {
  final String title;
  final Widget? action;
  const AdminTopBar({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.display(size: 20)),
        if (action != null) action!,
      ]),
    );
  }
}
