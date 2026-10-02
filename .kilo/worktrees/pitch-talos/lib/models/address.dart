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
}
