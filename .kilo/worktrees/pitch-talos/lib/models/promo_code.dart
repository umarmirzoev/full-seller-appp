enum DiscountType { percent, fixed }

class PromoCode {
  final String id;
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final DateTime? expiresAt;
  final int? usageLimit;
  final int timesUsed;

  const PromoCode({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.expiresAt,
    this.usageLimit,
    this.timesUsed = 0,
  });
}
