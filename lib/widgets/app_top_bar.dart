import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import 'logo_mark.dart';

class AppTopBar extends StatelessWidget {
  final bool showCart;
  final bool showNotifications;
  const AppTopBar({super.key, this.showCart = true, this.showNotifications = true});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const LogoMark(),
        Row(children: [
          if (showNotifications) _iconBtn(context, Icons.notifications_none_rounded, () => Navigator.pushNamed(context, AppRoutes.notifications), dot: true),
          if (showCart) ...[
            const SizedBox(width: 8),
            _iconBtn(context, Icons.shopping_cart_outlined, () => Navigator.pushNamed(context, AppRoutes.cart), count: cart.itemsCount),
          ],
        ]),
      ]),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap, {bool dot = false, int count = 0}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), shape: BoxShape.circle),
        child: Stack(clipBehavior: Clip.none, children: [
          Center(child: Icon(icon, size: 18, color: AppColors.text2)),
          if (dot)
            Positioned(top: 6, right: 7, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle))),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}
