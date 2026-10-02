import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';

enum AppCurrency { rub, usd }

/// Переключатель валюты ₽ / $ (ТЗ п.8). Курс сейчас берётся из моковых настроек,
/// после подключения бэкенда — из GET /api/settings.
class CurrencyProvider extends ChangeNotifier {
  AppCurrency _currency = AppCurrency.rub;
  double _usdToRubRate = MockData.appSettings.usdToRubRate;

  AppCurrency get currency => _currency;
  double get rate => _usdToRubRate;
  bool get isRub => _currency == AppCurrency.rub;

  void toggle(AppCurrency value) {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();
  }

  void setRate(double rate) {
    _usdToRubRate = rate;
    notifyListeners();
  }

  double convert(double rubPrice) => isRub ? rubPrice : rubPrice / _usdToRubRate;

  String format(double rubPrice) {
    final value = convert(rubPrice);
    final rounded = isRub ? value.round().toString() : value.toStringAsFixed(2);
    return isRub ? '$rounded ₽' : '\$$rounded';
  }
}
