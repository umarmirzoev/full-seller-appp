import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class SearchRow extends StatelessWidget {
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final String hint;
  const SearchRow({super.key, this.onFilterTap, this.onChanged, this.hint = 'Поиск по каталогу'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 18, color: AppColors.text3),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: onChanged,
                  decoration: InputDecoration.collapsed(hintText: hint, hintStyle: AppTextStyles.body(size: 13.5, color: AppColors.text3)),
                  style: AppTextStyles.body(size: 13.5),
                ),
              ),
            ]),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.text2),
            ),
          ),
        ],
      ]),
    );
  }
}
