import 'price_tier.dart';
import 'product_variant.dart';

/// Товар. Поля соответствуют ProductListItemDto / ProductDetailsDto бэкенда.
/// Примечание: публичные каталожные DTO backend'а не отдают oldPrice/isNew/isHit/brandName —
/// это доступно только в админском AdminProductDto. Пока подключаем как есть (без бейджей/бренда
/// на карточке при работе с реальным API) — можно расширить бэкенд отдельным шагом при необходимости.
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

  /// Из ProductListItemDto (GET /catalog/products, /catalog/search).
  factory Product.fromListItemJson(Map<String, dynamic> json, {String? brandName}) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        brandId: json['brandId'] as String?,
        brandName: brandName,
        minPrice: (json['minPrice'] as num).toDouble(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
        imageUrls: (json['imageUrls'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      );

  /// Из ProductDetailsDto (GET /catalog/products/{id}).
  factory Product.fromDetailsJson(Map<String, dynamic> json, {String? brandName}) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        brandId: json['brandId'] as String?,
        brandName: brandName,
        description: json['description'] as String?,
        composition: json['composition'] as String?,
        weightGrams: (json['weightGrams'] as num?)?.toInt() ?? 0,
        imageUrls: (json['imageUrls'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
        minPrice: (json['priceTiers'] as List<dynamic>? ?? const []).isEmpty
            ? 0
            : ((json['priceTiers'] as List<dynamic>)
                    .map((t) => (t['pricePerUnit'] as num).toDouble())
                    .reduce((a, b) => a < b ? a : b)),
        priceTiers: (json['priceTiers'] as List<dynamic>? ?? const [])
            .map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
            .toList(),
        variants: (json['variants'] as List<dynamic>? ?? const [])
            .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>, productId: json['id'] as String))
            .toList(),
      );
}
