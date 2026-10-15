/// 1:1 с backend DeliveryCountry (Russia=0, Tajikistan=1, Uzbekistan=2, Kazakhstan=3, Kyrgyzstan=4, Other=5).
enum DeliveryCountry { russia, tajikistan, uzbekistan, kazakhstan, kyrgyzstan, other }

extension DeliveryCountryX on DeliveryCountry {
  String get label {
    switch (this) {
      case DeliveryCountry.russia:
        return 'Россия';
      case DeliveryCountry.tajikistan:
        return 'Таджикистан';
      case DeliveryCountry.uzbekistan:
        return 'Узбекистан';
      case DeliveryCountry.kazakhstan:
        return 'Казахстан';
      case DeliveryCountry.kyrgyzstan:
        return 'Кыргызстан';
      case DeliveryCountry.other:
        return 'Другая страна';
    }
  }

  /// Страна по коду телефона аккаунта; если код не распознан — Узбекистан по умолчанию.
  static DeliveryCountry fromPhone(String? phone) {
    final p = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+992') || p.startsWith('992')) return DeliveryCountry.tajikistan;
    if (p.startsWith('+998') || p.startsWith('998')) return DeliveryCountry.uzbekistan;
    if (p.startsWith('+996') || p.startsWith('996')) return DeliveryCountry.kyrgyzstan;
    if (p.startsWith('+77')) return DeliveryCountry.kazakhstan;
    if (p.startsWith('+7') || p.startsWith('7')) return DeliveryCountry.russia;
    return DeliveryCountry.uzbekistan;
  }
}

class Address {
  final String id;
  final String title;
  final DeliveryCountry country;
  final String city;
  final String street;
  final bool isDefault;

  const Address({
    required this.id,
    required this.title,
    required this.country,
    required this.city,
    required this.street,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        title: json['city'] as String? ?? 'Адрес',
        country: DeliveryCountry.values[((json['country'] as num?)?.toInt() ?? 1).clamp(0, DeliveryCountry.values.length - 1)],
        city: json['city'] as String? ?? '',
        street: json['line'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
