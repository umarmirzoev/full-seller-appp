import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

/// Обёртка-карточка для таблиц/форм на десктопных admin-экранах.
class AdminCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets padding;
  const AdminCard({super.key, this.title, required this.child, this.padding = const EdgeInsets.all(22)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(padding.horizontal / 2, padding.vertical / 2, padding.horizontal / 2, 0),
            child: Text(title!, style: AppTextStyles.display(size: 15)),
          ),
        Padding(padding: padding, child: child),
      ]),
    );
  }
}
