import 'package:flutter/foundation.dart';
import '../services/settings_repository.dart';

enum AppCurrency { rub, usd }

/// Переключатель валюты ₽ / $ (ТЗ п.8). Курс подтягивается с backend (GET /api/settings)
/// и кэшируется в памяти на время сессии; при недоступности сервера используется резервное значение.
class CurrencyProvider extends ChangeNotifier {
  AppCurrency _currency = AppCurrency.rub;
  double _usdToRubRate = 90.0;

  AppCurrency get currency => _currency;
  double get rate => _usdToRubRate;
  bool get isRub => _currency == AppCurrency.rub;

  Future<void> loadRate() async {
    try {
      final settings = await SettingsRepository.getSettings();
      _usdToRubRate = settings.usdToRubRate;
      notifyListeners();
    } catch (_) {
      // остаёмся на резервном курсе, если backend недоступен
    }
  }

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
