class CartItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String? variantLabel;
  final double unitPrice;
  final int weightGrams;
  int quantity;

  CartItem({
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
}
