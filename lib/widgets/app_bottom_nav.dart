import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppTab { home, categories, ai, orders, profile }

class AppBottomNav extends StatelessWidget {
  final AppTab current;
  const AppBottomNav({super.key, required this.current});

  void _go(BuildContext context, AppTab tab) {
    if (tab == current) return;
    final route = switch (tab) {
      AppTab.home => AppRoutes.home,
      AppTab.categories => AppRoutes.categories,
      AppTab.ai => AppRoutes.fullAi,
      AppTab.orders => AppRoutes.orders,
      AppTab.profile => AppRoutes.profile,
    };
    if (tab == AppTab.ai) {
      Navigator.pushNamed(context, route);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _item(context, AppTab.home, Icons.home_rounded, 'Главная'),
          _item(context, AppTab.categories, Icons.grid_view_rounded, 'Каталог'),
          _aiItem(context),
          _item(context, AppTab.orders, Icons.inventory_2_outlined, 'Заказы'),
          _item(context, AppTab.profile, Icons.person_outline_rounded, 'Профиль'),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, AppTab tab, IconData icon, String label) {
    final active = tab == current;
    final color = active ? AppColors.primaryDark : AppColors.text3;
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, tab),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.body(size: 9.5, weight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _aiItem(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, AppTab.ai),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 20,
            width: 46,
            child: OverflowBox(
              maxHeight: 46,
              minHeight: 46,
              alignment: Alignment.topCenter,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.g500.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('FULL AI', style: AppTextStyles.body(size: 9.5, weight: FontWeight.w700, color: AppColors.primaryDark)),
        ]),
      ),
    );
  }
}
