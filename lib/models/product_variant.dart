class ProductVariant {
  final String id;
  final String productId;
  final String? size;
  final String? color;
  final String sku;
  final int stockQuantity;

  const ProductVariant({
    required this.id,
    required this.productId,
    this.size,
    this.color,
    required this.sku,
    required this.stockQuantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json, {String productId = ''}) => ProductVariant(
        id: json['id'] as String,
        productId: productId,
        size: json['size'] as String?,
        color: json['color'] as String?,
        sku: json['sku'] as String? ?? '',
        stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      );
}
