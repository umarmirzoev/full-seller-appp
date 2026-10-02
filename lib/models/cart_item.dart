class CartItem {
  /// Id позиции корзины на сервере (CartItemDto.Id) — нужен для update/delete. Пусто, пока
  /// позиция ещё не отправлена на backend (например, промежуточное локальное состояние).
  final String id;
  final String productVariantId;
  final String productId;
  final String productName;
  final String imageUrl;
  final String? variantLabel;
  final double unitPrice;
  final int weightGrams;
  int quantity;

  CartItem({
    this.id = '',
    this.productVariantId = '',
    required this.productId,
    required this.productName,
    required this.imageUrl,
    this.variantLabel,
    required this.unitPrice,
    this.weightGrams = 0,
    this.quantity = 1,
  });

  double get total => unitPrice * quantity;
  int get totalWeightGrams => weightGrams * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        productVariantId: json['productVariantId'] as String? ?? '',
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? '—',
        imageUrl: '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}
