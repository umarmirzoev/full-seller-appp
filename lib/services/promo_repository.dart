import 'api_client.dart';

class PromoValidation {
  final bool isValid;
  final String? error;
  final double discountAmount;
  final double finalAmount;
  const PromoValidation({required this.isValid, this.error, required this.discountAmount, required this.finalAmount});
}

class PromoRepository {
  PromoRepository._();

  static Future<PromoValidation> validate(String code, double orderAmount) async {
    final data = await ApiClient.instance.post('/promocodes/validate', body: {'code': code, 'orderAmount': orderAmount}, auth: false) as Map<String, dynamic>;
    return PromoValidation(
      isValid: data['isValid'] as bool,
      error: data['error'] as String?,
      discountAmount: (data['discountAmount'] as num).toDouble(),
      finalAmount: (data['finalAmount'] as num).toDouble(),
    );
  }
}
