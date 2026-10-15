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
          if (showNotifications)
            TopIconButton(icon: Icons.notifications_none_rounded, dot: true, onTap: () => Navigator.pushNamed(context, AppRoutes.notifications)),
          if (showCart) ...[
            const SizedBox(width: 10),
            TopIconButton(icon: Icons.shopping_cart_outlined, count: cart.itemsCount, onTap: () => Navigator.pushNamed(context, AppRoutes.cart)),
          ],
        ]),
      ]),
    );
  }
}

/// Круглая кнопка шапки с hover, нажатием и «прыгающим» счётчиком.
class TopIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final int count;
  const TopIconButton({super.key, required this.icon, required this.onTap, this.dot = false, this.count = 0});

  @override
  State<TopIconButton> createState() => _TopIconButtonState();
}

class _TopIconButtonState extends State<TopIconButton> {
  bool _h = false, _d = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _d = true),
        onTapUp: (_) => setState(() => _d = false),
        onTapCancel: () => setState(() => _d = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _d ? 0.9 : (_h ? 1.06 : 1),
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _h ? AppColors.g50 : AppColors.surface,
              border: Border.all(color: _h ? AppColors.g200 : AppColors.border, width: 1.3),
              shape: BoxShape.circle,
              boxShadow: _h ? [BoxShadow(color: AppColors.g500.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 5))] : null,
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              Center(child: Icon(widget.icon, size: 20, color: _h ? AppColors.g700 : AppColors.text2)),
              if (widget.dot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  ),
                ),
              if (widget.count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(widget.count),
                    tween: Tween(begin: 0.4, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (context, s, child) => Transform.scale(scale: s, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text('${widget.count}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
