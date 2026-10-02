/// 1:1 с backend DeliveryCountry (Russia=0, Tajikistan=1).
enum DeliveryCountry { russia, tajikistan }

extension DeliveryCountryX on DeliveryCountry {
  String get label => this == DeliveryCountry.russia ? 'Россия' : 'Таджикистан';
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
        country: DeliveryCountry.values[(json['country'] as num?)?.toInt() ?? 1],
        city: json['city'] as String? ?? '',
        street: json['line'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
