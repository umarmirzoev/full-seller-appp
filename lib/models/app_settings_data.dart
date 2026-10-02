/// Настройки магазина (курс валюты, мин. сумма заказа, контакты) — GET/PUT /api/settings.
class AppSettingsData {
  final double usdToRubRate;
  final DateTime rateUpdatedAt;
  final double minOrderAmount;
  final String? contactPhone;
  final String? contactAddress;
  final String? whatsAppUrl;
  final String? telegramUrl;

  const AppSettingsData({
    required this.usdToRubRate,
    required this.rateUpdatedAt,
    required this.minOrderAmount,
    this.contactPhone,
    this.contactAddress,
    this.whatsAppUrl,
    this.telegramUrl,
  });

  factory AppSettingsData.fromJson(Map<String, dynamic> json) => AppSettingsData(
        usdToRubRate: (json['usdToRubRate'] as num).toDouble(),
        rateUpdatedAt: DateTime.parse(json['rateUpdatedAt'] as String),
        minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
        contactPhone: json['contactPhone'] as String?,
        contactAddress: json['contactAddress'] as String?,
        whatsAppUrl: json['whatsAppUrl'] as String?,
        telegramUrl: json['telegramUrl'] as String?,
      );
}
