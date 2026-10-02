import '../models/address.dart';
import 'api_client.dart';

class DeliveryCalculation {
  final double weightKg;
  final double pricePerKg;
  final double totalCost;
  final String currency;
  const DeliveryCalculation({required this.weightKg, required this.pricePerKg, required this.totalCost, required this.currency});
}

class DeliveryRepository {
  DeliveryRepository._();

  static Future<DeliveryCalculation> calculate({required DeliveryCountry country, required int totalWeightGrams}) async {
    final data = await ApiClient.instance.post('/delivery/calculate',
        body: {'country': country.index, 'totalWeightGrams': totalWeightGrams}, auth: false) as Map<String, dynamic>;
    return DeliveryCalculation(
      weightKg: (data['weightKg'] as num).toDouble(),
      pricePerKg: (data['pricePerKg'] as num).toDouble(),
      totalCost: (data['totalCost'] as num).toDouble(),
      currency: data['currency'] as String,
    );
  }
}
