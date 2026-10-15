import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/currency_provider.dart';
import '../providers/favorites_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'badge_row.dart';
import 'placeholder_image.dart';

/// Карточка товара: при наведении поднимается, фото плавно увеличивается,
/// появляется кнопка «Подробнее»; сердечко «пружинит» при добавлении в избранное.
class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _h = false, _d = false;

  void _open() => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: widget.product.id);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currency = context.watch<CurrencyProvider>();
    final isFav = context.watch<FavoritesProvider>().isFavorite(product.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _d = true),
        onTapUp: (_) => setState(() => _d = false),
        onTapCancel: () => setState(() => _d = false),
        onTap: _open,
        child: AnimatedScale(
          scale: _d ? 0.97 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _h ? -6 : 0, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: _h ? AppColors.g200 : AppColors.borderSoft, width: 1.3),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.g900.withValues(alpha: _h ? 0.14 : 0.05),
                  blurRadius: _h ? 28 : 12,
                  offset: Offset(0, _h ? 14 : 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Stack(fit: StackFit.expand, children: [
                  AnimatedScale(
                    scale: _h ? 1.07 : 1,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    child: PlaceholderImage(
                      width: double.infinity,
                      height: double.infinity,
                      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
                    ),
                  ),
                  // лёгкое затемнение снизу при наведении
                  AnimatedOpacity(
                    opacity: _h ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x66000000)],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(top: 10, left: 10, child: BadgeRow(labels: product.badges)),
                  Positioned(top: 8, right: 8, child: _FavButton(isFav: isFav, onTap: () => context.read<FavoritesProvider>().toggle(product))),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: AnimatedSlide(
                      offset: _h ? Offset.zero : const Offset(0, 0.6),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: _h ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Подробнее', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w800, color: AppColors.g700)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.g700),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 4, children: [
                    Text(currency.format(product.minPrice), style: AppTextStyles.mono(size: 15.5, color: _h ? AppColors.g700 : AppColors.text)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('/шт', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                    ),
                    if (product.hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 1),
                        child: Text(
                          currency.format(product.oldPrice!),
                          style: AppTextStyles.mono(size: 11.5, weight: FontWeight.w600, color: AppColors.text3).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(size: 12.8, weight: FontWeight.w700, color: AppColors.text2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                    const SizedBox(width: 3),
                    Text(product.rating.toStringAsFixed(1), style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800)),
                    const Spacer(),
                    Text('${product.reviewsCount} отз.', style: AppTextStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.text3)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FavButton extends StatefulWidget {
  final bool isFav;
  final VoidCallback onTap;
  const _FavButton({required this.isFav, required this.onTap});

  @override
  State<_FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<_FavButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(covariant _FavButton old) {
    super.didUpdateWidget(old);
    if (widget.isFav && !old.isFav) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            final s = t == 0 ? 1.0 : 1 + 0.35 * (1 - (2 * t - 1).abs());
            return Transform.scale(scale: s, child: child);
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(
              widget.isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: widget.isFav ? AppColors.danger : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}
