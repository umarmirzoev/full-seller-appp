import 'price_tier.dart';
import 'product_variant.dart';

/// Товар. Поля соответствуют ProductListItemDto / ProductDetailsDto бэкенда,
/// плюс поля 2.0: oldPrice / isNew / isHit — бейджи «Новинка»/«Хит»/«Скидка».
class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? brandId;
  final String? brandName;
  final String? description;
  final String? composition;
  final int weightGrams;
  final List<String> imageUrls;
  final double rating;
  final int reviewsCount;
  final double minPrice;
  final double? oldPrice;
  final bool isNew;
  final bool isHit;
  final List<PriceTier> priceTiers;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.brandId,
    this.brandName,
    this.description,
    this.composition,
    this.weightGrams = 0,
    this.imageUrls = const [],
    this.rating = 0,
    this.reviewsCount = 0,
    required this.minPrice,
    this.oldPrice,
    this.isNew = false,
    this.isHit = false,
    this.priceTiers = const [],
    this.variants = const [],
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > minPrice;

  List<String> get badges => [
        if (isNew) 'Новинка',
        if (isHit) 'Хит',
        if (hasDiscount) 'Скидка',
      ];
}
