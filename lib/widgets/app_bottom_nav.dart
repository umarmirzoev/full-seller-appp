import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppTab { home, categories, ai, orders, profile }

/// Нижнее меню: активная вкладка подсвечивается «таблеткой», FULL AI — приподнятая
/// пульсирующая кнопка (подпись больше не налезает на кнопку), hover на вебе.
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [BoxShadow(color: AppColors.g900.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _NavItem(icon: Icons.home_rounded, label: 'Главная', active: current == AppTab.home, onTap: () => _go(context, AppTab.home)),
            _NavItem(icon: Icons.grid_view_rounded, label: 'Каталог', active: current == AppTab.categories, onTap: () => _go(context, AppTab.categories)),
            _AiItem(onTap: () => _go(context, AppTab.ai)),
            _NavItem(icon: Icons.inventory_2_outlined, label: 'Заказы', active: current == AppTab.orders, onTap: () => _go(context, AppTab.orders)),
            _NavItem(icon: Icons.person_outline_rounded, label: 'Профиль', active: current == AppTab.profile, onTap: () => _go(context, AppTab.profile)),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active;
    final color = on ? AppColors.g600 : (_h ? AppColors.text : AppColors.text3);
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: on ? 52 : (_h ? 44 : 36),
              height: 30,
              decoration: BoxDecoration(
                color: on ? AppColors.g50 : (_h ? AppColors.surface2 : Colors.transparent),
                borderRadius: BorderRadius.circular(15),
              ),
              child: AnimatedScale(
                scale: on ? 1.1 : (_h ? 1.06 : 1),
                duration: const Duration(milliseconds: 220),
                child: Icon(widget.icon, size: 21, color: color),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTextStyles.body(size: 10.5, weight: on ? FontWeight.w800 : FontWeight.w700, color: color),
              child: Text(widget.label),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AiItem extends StatefulWidget {
  final VoidCallback onTap;
  const _AiItem({required this.onTap});

  @override
  State<_AiItem> createState() => _AiItemState();
}

class _AiItemState extends State<_AiItem> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  bool _h = false;

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: _p,
              builder: (context, child) {
                final v = Curves.easeInOut.transform(_p.value);
                return Transform.scale(
                  scale: _h ? 1.08 : 1,
                  child: Container(
                    width: 42,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(color: AppColors.g500.withValues(alpha: 0.3 + 0.2 * v), blurRadius: 10 + 8 * v, spreadRadius: v * 2, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Transform.rotate(angle: (_h ? 0.25 : 0) + v * 0.12, child: child),
                  ),
                );
              },
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
            ),
            const SizedBox(height: 3),
            Text('FULL AI', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w800, color: AppColors.g600)),
          ]),
        ),
      ),
    );
  }
}
