import 'address.dart';

class CargoRate {
  final DeliveryCountry country;
  final double pricePerKg;
  final String currency;

  const CargoRate({required this.country, required this.pricePerKg, this.currency = 'RUB'});
}
