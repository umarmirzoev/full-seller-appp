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

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(product.id);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderSoft),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  const PlaceholderImage(width: double.infinity, height: double.infinity),
                  Positioned(top: 10, left: 10, child: BadgeRow(labels: product.badges)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => context.read<FavoritesProvider>().toggle(product),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 15, color: isFav ? AppColors.danger : AppColors.text2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(currency.format(product.minPrice), style: AppTextStyles.mono(size: 15)),
                    const SizedBox(width: 4),
                    Text('/шт', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(currency.format(product.oldPrice!),
                          style: AppTextStyles.mono(size: 11.5, weight: FontWeight.w600, color: AppColors.text3)
                              .copyWith(decoration: TextDecoration.lineThrough)),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(size: 12.5, color: AppColors.text2)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('★ ${product.rating.toStringAsFixed(1)}', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w700, color: AppColors.text3)),
                    Text('${product.reviewsCount} отз.', style: AppTextStyles.body(size: 10.5, weight: FontWeight.w600, color: AppColors.text3)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
