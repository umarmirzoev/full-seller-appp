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
}
