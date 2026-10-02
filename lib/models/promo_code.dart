/// 1:1 с backend DiscountType (Percent=0, Fixed=1).
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

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
        id: json['id'] as String,
        code: json['code'] as String,
        discountType: DiscountType.values[(json['discountType'] as num?)?.toInt() ?? 0],
        discountValue: (json['discountValue'] as num).toDouble(),
        expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
        usageLimit: (json['usageLimit'] as num?)?.toInt(),
        timesUsed: (json['timesUsed'] as num?)?.toInt() ?? 0,
      );
}
