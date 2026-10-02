class PriceTier {
  final int minQuantity;
  final double pricePerUnit;

  const PriceTier({required this.minQuantity, required this.pricePerUnit});

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
        minQuantity: (json['minQuantity'] as num).toInt(),
        pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      );
}
