/// Настройки магазина для экрана AdminSettings (курс валюты, мин. сумма заказа, контакты).
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
}
