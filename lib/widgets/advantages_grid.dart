import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

class AdvantagesGrid extends StatelessWidget {
  const AdvantagesGrid({super.key});

  static const _items = [
    ('truck', 'Доставка от 1 дня', 'РФ и Таджикистан'),
    ('shield', 'Гарантия качества', 'Проверка перед отправкой'),
    ('wallet', 'Оптовые цены', 'Чем больше — тем дешевле'),
    ('chat_outlined', 'Поддержка 24/7', 'Онлайн-чат с менеджером'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: _items.map((item) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(item.$1 == 'chat_outlined' ? Icons.chat_bubble_outline_rounded : appIcon(item.$1), size: 18, color: AppColors.primaryDark),
              const SizedBox(height: 6),
              Text(item.$2, style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800)),
              Text(item.$3, style: AppTextStyles.body(size: 10, weight: FontWeight.w600, color: AppColors.text3)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
