import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../models/review.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/favorites_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_exception.dart';
import '../services/catalog_repository.dart';
import '../services/reviews_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/badge_row.dart';
import '../widgets/currency_toggle.dart';
import '../widgets/placeholder_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _galleryIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 50;
  bool _loading = true;
  bool _addingToCart = false;
  String? _error;
  Product? _product;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CatalogRepository.getProduct(widget.productId),
        ReviewsRepository.getByProduct(widget.productId),
      ]);
      final product = results[0] as Product;
      final reviews = results[1] as List<Review>;
      if (!mounted) return;
      setState(() {
        _product = product;
        _reviews = reviews;
        if (product.variants.isNotEmpty) {
          _selectedSize = product.variants.first.size;
          _selectedColor = product.variants.first.color;
        }
        _quantity = product.priceTiers.isNotEmpty ? product.priceTiers.first.minQuantity : 50;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить товар';
      });
    }
  }

  double _priceFor(Product product, int qty) {
    var price = product.minPrice;
    for (final tier in product.priceTiers) {
      if (qty >= tier.minQuantity) price = tier.pricePerUnit;
    }
    return price;
  }

  ProductVariant? _matchingVariant(Product product) {
    if (product.variants.isEmpty) return null;
    for (final v in product.variants) {
      if (v.size == _selectedSize && v.color == _selectedColor) return v;
    }
    return product.variants.first;
  }

  Future<void> _addToCart(Product product) async {
    final variant = _matchingVariant(product);
    if (variant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Для этого товара нет доступных вариантов для заказа')));
      return;
    }
    setState(() => _addingToCart = true);
    try {
      await context.read<CartProvider>().addVariant(variant.id, quantity: _quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено в корзину')));
      Navigator.pushNamed(context, AppRoutes.cart);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось добавить товар в корзину')));
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Товар не найден', style: AppTextStyles.body(color: AppColors.text3))),
      );
    }

    final reviews = _reviews;
    final currency = context.watch<CurrencyProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(product.id);
    final sizes = product.variants.map((v) => v.size).whereType<String>().toSet().toList();
    final colors = product.variants.map((v) => v.color).whereType<String>().toSet().toList();
    final unitPrice = _priceFor(product, _quantity);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
              const CurrencyToggle(),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: PlaceholderImage(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.circular(0)),
                  ),
                  Positioned(top: 14, left: 20, child: BadgeRow(labels: product.badges)),
                  Positioned(
                    top: 10,
                    right: 16,
                    child: InkWell(
                      onTap: () => context.read<FavoritesProvider>().toggle(product),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? AppColors.danger : AppColors.text2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(product.imageUrls.isEmpty ? 1 : product.imageUrls.length, (i) {
                        final active = i == _galleryIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6, height: 6,
                          decoration: BoxDecoration(color: active ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(4)),
                        );
                      }),
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (product.brandName != null)
                      Text(product.brandName!.toUpperCase(), style: AppTextStyles.body(size: 11, weight: FontWeight.w800, color: AppColors.primaryDark).copyWith(letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(product.name, style: AppTextStyles.display(size: 19)),
                    const SizedBox(height: 8),
                    Row(children: [
                      StarRating(rating: product.rating, size: 15),
                      const SizedBox(width: 6),
                      Text('${product.rating} · ${product.reviewsCount} отзывов', style: AppTextStyles.body(size: 12, weight: FontWeight.w600, color: AppColors.text3)),
                    ]),
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(currency.format(unitPrice), style: AppTextStyles.mono(size: 26)),
                      const SizedBox(width: 6),
                      Text('/ шт', style: AppTextStyles.body(size: 12, color: AppColors.text3)),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(currency.format(product.oldPrice!),
                            style: AppTextStyles.mono(size: 14, weight: FontWeight.w600, color: AppColors.text3).copyWith(decoration: TextDecoration.lineThrough)),
                      ],
                    ]),
                    const SizedBox(height: 20),
                    if (product.priceTiers.isNotEmpty) ...[
                      Text('ОПТОВАЯ ШКАЛА ЦЕН', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: AppColors.borderSoft), borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Column(
                          children: product.priceTiers.asMap().entries.map((e) {
                            final tier = e.value;
                            final isLast = e.key == product.priceTiers.length - 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.borderSoft))),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('от ${tier.minQuantity} шт', style: AppTextStyles.body(size: 13, weight: FontWeight.w700)),
                                Text(currency.format(tier.pricePerUnit), style: AppTextStyles.mono(size: 13.5)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (sizes.isNotEmpty) ...[
                      Text('РАЗМЕР', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: sizes.map((s) => _pill(s, s == _selectedSize, () => setState(() => _selectedSize = s))).toList()),
                      const SizedBox(height: 20),
                    ],
                    if (colors.isNotEmpty) ...[
                      Text('ЦВЕТ', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: colors.map((c) => _pill(c, c == _selectedColor, () => setState(() => _selectedColor = c))).toList()),
                      const SizedBox(height: 20),
                    ],
                    Text('КОЛИЧЕСТВО', style: AppTextStyles.body(size: 11.5, weight: FontWeight.w800, color: AppColors.text3).copyWith(letterSpacing: 0.4)),
                    const SizedBox(height: 8),
                    QuantityStepper(value: _quantity, min: 1, step: 10, onChanged: (v) => setState(() => _quantity = v)),
                    const SizedBox(height: 22),
                    if (product.description != null) ...[
                      Text('Описание', style: AppTextStyles.display(size: 15)),
                      const SizedBox(height: 8),
                      Text(product.description!, style: AppTextStyles.body(size: 13.5, weight: FontWeight.w500, color: AppColors.text2)),
                      const SizedBox(height: 8),
                    ],
                    if (product.composition != null)
                      Text('Состав: ${product.composition}', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                    Text('Вес: ${product.weightGrams} г / шт', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Отзывы', style: AppTextStyles.display(size: 15)),
                    ]),
                  ]),
                ),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text('Пока нет отзывов', style: AppTextStyles.body(size: 12.5, weight: FontWeight.w600, color: AppColors.text3)),
                  )
                else
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => ReviewCard(review: reviews[i]),
                    ),
                  ),
                const SizedBox(height: 110),
              ]),
            ),
          ),
        ]),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderSoft))),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Итого', style: AppTextStyles.body(size: 11, weight: FontWeight.w700, color: AppColors.text3)),
              Text(currency.format(unitPrice * _quantity), style: AppTextStyles.mono(size: 17)),
            ]),
          ),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              icon: _addingToCart
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shopping_cart_outlined, size: 18),
              label: const Text('В корзину'),
              onPressed: _addingToCart ? null : () => _addToCart(product),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pill(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }
}
