import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            Row(children: [
              CircleAvatar(radius: 32, backgroundColor: AppColors.g100,
                  child: Text(user.initials, style: AppTextStyles.display(size: 20, color: AppColors.primaryDark))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: AppTextStyles.display(size: 17)),
                  const SizedBox(height: 3),
                  Text(user.phone, style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                  if (user.isLegalEntity) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.g50, borderRadius: BorderRadius.circular(999)),
                      child: Text(user.legalName ?? 'Юр. лицо', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.primaryDark)),
                    ),
                  ],
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _statCard('${user.loyaltyPoints}', 'Баллов лояльности')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('${favorites.count}', 'В избранном')),
            ]),
            const SizedBox(height: 20),
            _menuTile(context, Icons.inventory_2_outlined, 'Мои заказы', () => Navigator.pushNamed(context, AppRoutes.orders)),
            _menuTile(context, Icons.favorite_border_rounded, 'Избранное', () => Navigator.pushNamed(context, AppRoutes.favorites)),
            _menuTile(context, Icons.local_shipping_outlined, 'Калькулятор доставки', () => Navigator.pushNamed(context, AppRoutes.cargoCalculator)),
            _menuTile(context, Icons.chat_bubble_outline_rounded, 'Чат с менеджером', () => Navigator.pushNamed(context, AppRoutes.chat)),
            const SizedBox(height: 8),
            Text('ПОСТАВЩИКАМ', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
            const SizedBox(height: 10),
            _menuTile(context, Icons.storefront_outlined, 'Профиль поставщика', () => Navigator.pushNamed(context, AppRoutes.sellerProfile)),
            _menuTile(context, Icons.dashboard_outlined, 'Дашборд', () => Navigator.pushNamed(context, AppRoutes.dashboard)),
            _menuTile(context, Icons.list_alt_rounded, 'Мои товары', () => Navigator.pushNamed(context, AppRoutes.myListings)),
            _menuTile(context, Icons.bolt_rounded, 'Быстрый заказ', () => Navigator.pushNamed(context, AppRoutes.quickOrder)),
            _menuTile(context, Icons.bar_chart_rounded, 'Админ-панель (режим ноутбука)', () => Navigator.pushNamed(context, AppRoutes.adminDashboard)),
            const SizedBox(height: 8),
            _menuTile(context, Icons.settings_outlined, 'Настройки', () {}),
            _menuTile(context, Icons.logout_rounded, 'Выйти', () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false), danger: true),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.profile),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTextStyles.display(size: 20)),
        Text(label, style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.text3)),
      ]),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 19, color: danger ? AppColors.danger : AppColors.text2),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.text))),
          if (!danger) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.text3),
        ]),
      ),
    );
  }
}
