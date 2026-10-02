import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

class CategoryStrip extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onTap;
  const CategoryStrip({super.key, required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          return GestureDetector(
            onTap: () => onTap(c),
            child: SizedBox(
              width: 64,
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(18)),
                  child: Icon(appIcon(c.iconName), color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(height: 6),
                Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(size: 10.5, weight: FontWeight.w700, color: AppColors.text2)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
