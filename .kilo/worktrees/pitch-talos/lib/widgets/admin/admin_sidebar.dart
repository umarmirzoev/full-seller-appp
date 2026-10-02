import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../logo_mark.dart';

class AdminSidebar extends StatelessWidget {
  final String active;
  const AdminSidebar({super.key, required this.active});

  static const _items = [
    ('Дашборд', Icons.bar_chart_rounded, AppRoutes.adminDashboard),
    ('Каталог', Icons.archive_outlined, AppRoutes.adminCatalog),
    ('Заказы', Icons.inventory_2_outlined, AppRoutes.adminOrders),
    ('Калькулятор доставки', Icons.local_shipping_outlined, AppRoutes.adminCalculator),
    ('Настройки', Icons.settings_outlined, AppRoutes.adminSettings),
  ];

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(right: BorderSide(color: AppColors.borderSoft))),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const LogoMark(),
            const SizedBox(height: 4),
            Text('Панель поставщика', style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.text3)),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: _items.map((item) {
              final isActive = item.$1 == active;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: isActive ? AppColors.g50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () {
                      if (!isActive) Navigator.pushReplacementNamed(context, item.$3);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(children: [
                        Icon(item.$2, size: 18, color: isActive ? AppColors.primaryDark : AppColors.text2),
                        const SizedBox(width: 12),
                        Text(item.$1, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: isActive ? AppColors.primaryDark : AppColors.text2)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderSoft))),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                CircleAvatar(radius: 19, backgroundColor: AppColors.g100,
                    child: Text(user.initials, style: AppTextStyles.display(size: 13, color: AppColors.primaryDark))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w700)),
                    Text('Менеджер', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                  ]),
                ),
                const Icon(Icons.settings_outlined, size: 16, color: AppColors.text3),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
